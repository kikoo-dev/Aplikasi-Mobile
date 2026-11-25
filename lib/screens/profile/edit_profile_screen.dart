import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _jobCtrl;
  late final TextEditingController _igCtrl;
  late final TextEditingController _fbCtrl;
  late final TextEditingController _ttCtrl;

  DateTime? _birthDate;
  String _gender = '';
  bool _saving = false;
  Uint8List? _pickedBytes;
  bool _uploading = false;

  static const List<String> _genders = ['Laki-laki', 'Perempuan', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final p = AppScope.read(context).profile ?? UserProfile.empty;

    _nameCtrl = TextEditingController(text: p.fullName);
    _usernameCtrl = TextEditingController(text: p.username);
    _phoneCtrl = TextEditingController(text: p.phone);
    _bioCtrl = TextEditingController(text: p.bio);
    _aboutCtrl = TextEditingController(text: p.aboutMe);
    _addressCtrl = TextEditingController(text: p.address);
    _jobCtrl = TextEditingController(text: p.occupation);
    _igCtrl = TextEditingController(text: p.instagram);
    _fbCtrl = TextEditingController(text: p.facebook);
    _ttCtrl = TextEditingController(text: p.tiktok);
    _birthDate = p.birthDate;
    _gender = _genders.contains(p.gender) ? p.gender : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _aboutCtrl.dispose();
    _addressCtrl.dispose();
    _jobCtrl.dispose();
    _igCtrl.dispose();
    _fbCtrl.dispose();
    _ttCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 82,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        showAppSnack(
          context,
          'Ukuran foto terlalu besar (maks 5 MB).',
          isError: true,
        );
        return;
      }
      setState(() => _pickedBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Gagal memilih gambar: $e', isError: true);
    }
  }

  /// Bottom sheet pilihan sumber foto: kamera atau galeri.
  Future<void> _showPhotoOptions() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ganti Foto Profil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih sumber foto yang ingin digunakan',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PhotoOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(fromCamera: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final controller = AppScope.read(context);

    try {
      var profile = (controller.profile ?? UserProfile.empty).copyWith(
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        aboutMe: _aboutCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        occupation: _jobCtrl.text.trim(),
        gender: _gender,
        instagram: _igCtrl.text.trim(),
        facebook: _fbCtrl.text.trim(),
        tiktok: _ttCtrl.text.trim(),
        birthDate: _birthDate,
        clearBirthDate: _birthDate == null,
      );

      // Upload foto terlebih dahulu (jika ada).
      if (_pickedBytes != null) {
        setState(() => _uploading = true);
        final url = await controller.uploadAvatar(
          bytes: _pickedBytes!,
          fileName: 'avatar.jpg',
        );
        profile = profile.copyWith(avatarUrl: url);
        setState(() => _uploading = false);
      }

      await controller.saveProfile(profile);

      if (!mounted) return;
      showAppSnack(context, 'Profil berhasil disimpan ✨');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context);
    final profile = controller.profile ?? UserProfile.empty;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                PageHeader(
                  title: 'Edit Profil',
                  subtitle: 'Lengkapi biodata & sosial media',
                  trailing: TextButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Simpan'),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Foto profil ----------
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ProfileAvatar(
                            profile: profile,
                            size: 104,
                            localBytes: _pickedBytes,
                            showEditBadge: true,
                            onTap: _saving ? null : _showPhotoOptions,
                          ),
                          if (_uploading)
                            Container(
                              width: 104,
                              height: 104,
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _saving ? null : _showPhotoOptions,
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'Ganti Foto Profil',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickedBytes != null
                            ? 'Foto baru dipilih — tekan Simpan untuk menerapkan'
                            : 'Format JPG/PNG, maksimal 5 MB',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _pickedBytes != null
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white38
                                  : AppColors.inkMuted),
                          fontWeight: _pickedBytes != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (_pickedBytes != null)
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _pickedBytes = null),
                          icon: const Icon(Icons.undo_rounded, size: 15),
                          label: const Text(
                            'Batalkan foto baru',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ---------- Biodata ----------
                _FormCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Biodata',
                  children: [
                    LabeledField(
                      label: 'Nama Lengkap',
                      required: true,
                      child: TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Nama lengkap kamu',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Username',
                      required: true,
                      child: TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'username',
                          prefixIcon:
                              Icon(Icons.alternate_email_rounded, size: 20),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Username wajib diisi';
                          final ok =
                              RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value);
                          return ok
                              ? null
                              : 'Hanya huruf, angka, titik & underscore';
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'No. Telepon',
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          hintText: '08xxxxxxxxxx',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Tanggal Lahir',
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.cake_outlined, size: 20),
                            suffixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 17,
                            ),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'Pilih tanggal'
                                : formatTanggal(_birthDate!),
                            style: TextStyle(
                              fontSize: 14.5,
                              color: _birthDate == null
                                  ? (isDark
                                      ? Colors.white38
                                      : const Color(0xFF9A94B8))
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1B1436)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Jenis Kelamin',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _genders.map((g) {
                          final selected = _gender == g;
                          return GestureDetector(
                            onTap: () => setState(() => _gender = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF2F0FC)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white60
                                          : const Color(0xFF6B6488)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Pekerjaan',
                      child: TextFormField(
                        controller: _jobCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Mahasiswa, Desainer, dll.',
                          prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Alamat',
                      child: TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Kota, provinsi',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ---------- Tentang ----------
                _FormCard(
                  icon: Icons.info_outline_rounded,
                  title: 'About Me',
                  children: [
                    LabeledField(
                      label: 'Bio Singkat',
                      child: TextFormField(
                        controller: _bioCtrl,
                        maxLength: 90,
                        decoration: const InputDecoration(
                          hintText: 'Satu kalimat tentang kamu',
                          counterText: '',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Tentang Saya',
                      child: TextFormField(
                        controller: _aboutCtrl,
                        maxLines: 6,
                        maxLength: 600,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Ceritakan lebih detail tentang dirimu, minat, '
                              'dan hal yang kamu sukai...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ---------- Sosial media ----------
                _FormCard(
                  icon: Icons.share_outlined,
                  title: 'Sosial Media',
                  subtitle: 'Cukup isi username tanpa tanda @',
                  children: [
                    _SocialField(
                      controller: _igCtrl,
                      label: 'Instagram',
                      hint: 'username',
                      icon: Icons.camera_alt_rounded,
                      gradient: AppColors.instagramGradient,
                      prefix: 'instagram.com/',
                    ),
                    const SizedBox(height: 14),
                    _SocialField(
                      controller: _fbCtrl,
                      label: 'Facebook',
                      hint: 'username',
                      icon: Icons.facebook_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1877F2), Color(0xFF0F5FD1)],
                      ),
                      prefix: 'facebook.com/',
                    ),
                    const SizedBox(height: 14),
                    _SocialField(
                      controller: _ttCtrl,
                      label: 'TikTok',
                      hint: 'username',
                      icon: Icons.music_note_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F1F1F), Color(0xFF000000)],
                      ),
                      prefix: 'tiktok.com/@',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GradientButton(
                  label: 'Simpan Perubahan',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.orangeSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _FormCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1436),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white38 : const Color(0xFFA9A3C2),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Gradient gradient;
  final String prefix;

  const _SocialField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.gradient,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : const Color(0xFFA9A3C2),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
        ),
      ],
    );
  }
}
