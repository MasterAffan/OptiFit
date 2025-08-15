# 🤝 Contributing to OptiFit

Thank you for your interest in contributing to **OptiFit**! 💪 We welcome contributions from developers, designers, and fitness enthusiasts of all skill levels.

Our goal is to keep the app **clean, consistent, and user-friendly**, while leveraging **AI** to make fitness smarter.

---

## 📜 Code of Conduct

By participating, you agree to uphold our principles:

* Be respectful, kind, and constructive 🙌
* Keep discussions friendly and on-topic 🗣️
* Help create a welcoming community 💙

---

## 🚀 How to Contribute

### 1️⃣ Fork & Clone the Repository

```bash
git clone https://github.com/<your-username>/OptiFit.git
cd OptiFit
```

### 2️⃣ Create a Branch

```bash
git checkout -b feature/amazing-feature
```

### 3️⃣ Make Your Changes

* Follow the **naming conventions** and **UI/UX guidelines** listed in the README 📖
* Keep the **modular folder structure** intact 🗂️
* Use `AppTheme` for all colors, padding, and styles 🎨
* Maintain **green top-of-screen snackbars** for all save/notify actions ✅
* Add new assets to `/assets` and register them in `pubspec.yaml` 🖼️

### 4️⃣ Test Your Changes

* Run the Flutter app locally:

```bash
flutter pub get
flutter run
```

* Ensure there are no errors or style inconsistencies 🧹

### 5️⃣ Commit Your Changes

```bash
git commit -m "✨ Added: Amazing feature description"
```

### 6️⃣ Push & Open a PR

```bash
git push origin feature/amazing-feature
```

* Go to the original repo and click **New Pull Request** 📩

---

## 📂 Project Conventions

### 📁 File Naming

* **Screens:** `screen_name_screen.dart` (e.g., `profile_screen.dart`)
* **Models:** `model_name.dart` (e.g., `workout_model.dart`)
* **Widgets:** `widget_name.dart`

### 📐 Class & Variable Naming

* **Classes:** `PascalCase` (e.g., `ProfileScreen`)
* **Variables/Methods:** `camelCase` (e.g., `getUserData`)

### 🎨 UI/UX Rules

* All colors, padding, and radii → `AppTheme`
* Snackbars → **Green, top-of-screen, floating, 2s auto-dismiss**
* Profile images → Always `assets/profile.png` fallback
* FAQ → Use `ExpansionTile`
* Navigation → Auto-navigate back after snackbar dismiss

---

## 🛠️ Areas to Contribute

* 🖥️ **Frontend:** New screens, widgets, UI improvements
* 🤖 **AI Integration:** Enhancements to AI workout analysis
* 🐞 **Bug Fixes:** Solve open issues from GitHub Issues
* 📊 **Backend:** API improvements (Flask)
* 📄 **Docs:** Improve README, add tutorials

---

## 📌 Tips for a Great PR

* Keep PRs **small and focused** 🎯
* Use **clear commit messages**
* Add screenshots or screen recordings if UI changes 🎥
* Link related issues in your PR description 🔗

---

## 💬 Communication & Help

If you have any questions or ideas:

* Open a GitHub **Discussion** 💭
* Comment on related **Issues** 📌
* Reach out via project maintainers 📧

---

## ⭐ Recognition

We value **all contributions** — whether it's fixing a typo or adding a major feature. Your name will be added to our contributors' list! 🏆

Let's make **OptiFit** the smartest and most user-friendly AI fitness app together! 💪🤖
