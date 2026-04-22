/// VigilionX - Trusted Contacts Management Screen
/// Full CRUD for emergency contacts with add/edit/delete functionality.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/emergency_contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E21), Color(0xFF141A2E)],
                )
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                    const Expanded(
                      child: Text(
                        'Trusted Contacts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showContactDialog(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // Contacts list
              Expanded(
                child: Consumer<ContactsProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (!provider.hasContacts) {
                      return EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: 'No Trusted Contacts',
                        subtitle:
                            'Add your emergency contacts so they can be '
                            'notified when you trigger an SOS alert.',
                        buttonText: 'Add Contact',
                        onButtonPressed: () => _showContactDialog(context),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.contacts.length,
                      itemBuilder: (context, index) {
                        final contact = provider.contacts[index];
                        return _ContactTile(
                          contact: contact,
                          onEdit: () =>
                              _showContactDialog(context, contact: contact),
                          onDelete: () => _deleteContact(context, contact),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, {EmergencyContact? contact}) {
    final isEdit = contact != null;
    final nameController = TextEditingController(text: contact?.name);
    final phoneController = TextEditingController(text: contact?.phone);
    final emailController = TextEditingController(text: contact?.email);
    final formKey = GlobalKey<FormState>();
    String selectedRelation = contact?.relation ?? 'Family';

    final relations = [
      'Family', 'Friend', 'Spouse', 'Parent', 'Sibling', 'Colleague', 'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          isEdit ? 'Edit Contact' : 'Add Trusted Contact',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        AppTextField(
                          controller: nameController,
                          hint: 'Contact name',
                          label: 'Name',
                          prefixIcon: Icons.person_outline,
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: phoneController,
                          hint: 'Phone number',
                          label: 'Phone',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: emailController,
                          hint: 'Email (optional)',
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Relation selector
                        const Text(
                          'Relation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: relations.map((r) {
                            final isSelected = selectedRelation == r;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedRelation = r);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: AppColors.primaryGradient)
                                      : null,
                                  color: isSelected ? null : AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : AppColors.textMuted.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  r,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        GradientButton(
                          text: isEdit ? 'Update Contact' : 'Add Contact',
                          icon: isEdit ? Icons.edit : Icons.person_add,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final uid = Provider.of<AuthProvider>(context,
                                    listen: false)
                                .uid;
                            if (uid == null) return;

                            final provider = Provider.of<ContactsProvider>(
                                context,
                                listen: false);

                            bool success;
                            if (isEdit) {
                              success = await provider.updateContact(
                                contact!.copyWith(
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  email: emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
                                  relation: selectedRelation,
                                ),
                              );
                            } else {
                              success = await provider.addContact(
                                ownerUid: uid,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                email: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                relation: selectedRelation,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              Helpers.showSnackbar(
                                context,
                                success
                                    ? (isEdit
                                        ? 'Contact updated'
                                        : 'Contact added')
                                    : 'Operation failed',
                                isSuccess: success,
                                isError: !success,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteContact(BuildContext context, EmergencyContact contact) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Delete Contact',
      message:
          'Remove ${contact.name} from your trusted contacts? They will no '
          'longer receive SOS alerts.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirm && context.mounted) {
      final provider =
          Provider.of<ContactsProvider>(context, listen: false);
      final success = await provider.deleteContact(contact.id);
      if (context.mounted) {
        Helpers.showSnackbar(
          context,
          success ? 'Contact deleted' : 'Failed to delete',
          isSuccess: success,
          isError: !success,
        );
      }
    }
  }
}

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getRelationColor(contact.relation);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty 
                    ? contact.name.substring(0, 1).toUpperCase() 
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        contact.phone,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textLight
                              : AppColors.textDarkSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.first.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        contact.relation,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.first,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getRelationColor(String relation) {
    switch (relation.toLowerCase()) {
      case 'family':
        return AppColors.primaryGradient;
      case 'friend':
        return AppColors.accentGradient;
      case 'spouse':
        return AppColors.safeGradient;
      case 'parent':
        return AppColors.purpleGradient;
      default:
        return const [Color(0xFFFF9800), Color(0xFFF57C00)];
    }
  }
}
