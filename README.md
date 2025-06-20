1 · Check your toolbox  (once per machine)

Purpose	Minimum version	How to check

Git	2.34 +	git --version
Flutter SDK	3.22 (“stable”)	flutter --version
Android SDK + device/emulator	API 30 +	flutter doctor
Python (backend)	3.9 – 3.12	python --version
pip	matches Python	pip --version
Ollama	0.1.34 +	ollama 
(Optional) scrcpy	2.4 +	scrcpy --version

---

2 · Clone the repo

git clone https://github.com/KoTBTano4Ke/DiplomGit.git
cd DiplomGit

DiplomGit/
 ├─ front+llm/
 │   ├─ mobile_app/      <- Flutter project (lib/, pubspec.yaml, etc.)
 │   └─ serv1/           <- Flask + LLM backend (app.py, requirements.txt)
 └─ scrcpy-win64-v3.3/   <- Pre-built scrcpy (optional)

---

3 · Start the AI backend

# 3-A. Create & activate a virtual-env (recommended)
cd front+llm/serv1
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS/Linux
source .venv/bin/activate

# 3-B. Install Python deps
pip install -r requirements.txt

# 3-C. Pull the base LLM (one-time, ~4 GB by default)
ollama run llama3

# 3-D. Export any secrets the server needs
$env:OPENAI_API_KEY   = "<if you proxy through OpenAI>"
$env:FLASK_ENV        = "production"      # optional
$env:ALLOWED_ORIGINS  = "*"               # CORS, dev only

# 3-E. Fire it up
python app.py          # default: http://0.0.0.0:5001

---

4 · Configure Firebase (one-time)

1. Create/locate your Firebase project in the console.


2. Add an Android app → download google-services.json.


3. Add an iOS app (if you need iPhone) → download GoogleService-Info.plist.


4. Copy the files into the Flutter project roots:

front+llm/mobile_app/android/app/google-services.json
front+llm/mobile_app/ios/Runner/GoogleService-Info.plist

5. From the Flutter project folder run:

flutter pub global activate flutterfire_cli
flutterfire configure

That generates lib/firebase_options.dart, which the code expects.

---

5 · Run the Flutter client

cd ../mobile_app          # still inside front+llm
flutter pub get           # fetch Dart deps
flutter run -d <device>   # pick emulator, usb, or chrome

Common tweaks

What you change	Where

Backend URL	lib/constants.dart → const apiBase = 'http://192.168.1.96:5001';
App name / icon	android/app/src/main/res/, ios/Runner/Assets.xcassets
Internet permission (physical Android)	android/app/src/main/AndroidManifest.xml → add <uses-permission android:name="android.permission.INTERNET"/>

When everything is wired correctly:

Starting a workout writes XP/level data to Firebase RTDB at /users/{uid}/.

Pressing the floating “Chat” button pushes a route to ChatPage, which POSTs prompts to /chat on your Flask server and displays WeiderGPT’s answer on the left.

---

6 · (Option) Mirror a real phone with scrcpy

scrcpy-win64-v3.3\scrcpy.exe   # Windows  
# or just 'scrcpy' if it's on PATH on macOS/Linux

USB-debugging on, approve RSA fingerprint, done.


---

7 · Build & ship

Goal	Command

Release APK	flutter build apk --release
iOS archive	flutter build ipa --release (macOS + Xcode)
Systemd service for backend	gunicorn -w 4 -b 0.0.0.0:5001 app:app
Docker (backend)	docker build -t weidergpt . && docker run -p 5001:5001 weidergpt



---

8 · Troubleshooting checklist

1. ModuleNotFoundError in Python – virtual-env not activated or pip install -r requirements.txt missing.
2. Connection refused in Flutter logs – phone and PC not on same network / wrong apiBase.
3. SHA-1 fingerprint missing when logging in via Google – add your debug and release SHA-1 keys in Firebase console.
4. APK installs but crashes instantly – forget to copy google-services.json, or ProGuard stripped icons; rebuild with --no-shrink flag to test.
5. Model loads slowly first time – Ollama has to pull and quantize the weights once; subsequent starts are quick.

