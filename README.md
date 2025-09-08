# Авторство та умови використання

**Автор:** Shade_Furry (Фурік)  
**GitHub:** [https://github.com/Mamoru90-coder-python-furry-love/Linux-Arizona-Rp-Launcher-Beta](https://github.com/Mamoru90-coder-python-furry-love/Linux-Arizona-Rp-Launcher-Beta)

Цей репозиторій містить **Linux лаунчер для Arizona RP**. Скрипти є **open-source**, тобто ви можете:

- Використовувати їх для запуску та тестування.
- Ознайомлюватися з кодом.

❗ **ВАЖЛИВО:**  
- Будь-які модифікації або поширення скриптів **потребують письмової згоди автора**.  
- Копіювання без дозволу або представлення як свій власний проєкт заборонено.  
- Якщо ви бажаєте зробити зміни, **спершу зв’яжіться з автором** через GitHub або Telegram (@shadefurry).  

Дотримання цих умов допомагає зберегти авторські права та контроль над розвитком проєкту.

# Arizona RP Linux Launcher – V0.2 Pre Release

Лаунчер для **Arizona RP** на Linux, який автоматизує запуск **SA-MP** через **Wine/Proton**, перевірку цілісності файлів та моніторинг системи.

⚠️ Скрипти можуть оновлюватися у майбутньому, але автор не гарантує регулярні апдейти.

---

## Доступні версії

### 1️⃣ Lite Edition

* Швидкий запуск SAMP через Wine
* Автоматичне створення Wine-префіксу
* Пряме підключення до серверів Arizona RP
* Мінімальні залежності
* Консольний режим

### 2️⃣ Supra Edition

* Повна автоматизація: **Proton GE + Wine-префікс + SAMP**
* Моніторинг системи та гри (CPU, RAM, Disk)
* Управління через FIFO: `/on`, `/off`, `/info`, `/restart`, `/update`
* Логи, кольоровий вивід, захист від повторного запуску
* Графічний інтерфейс через Zenity + консольний режим

---

## Установка

```bash
git clone https://github.com/Mamoru90-coder-python-furry-love/Linux-Arizona-Rp-Launcher-Beta.git
cd Linux-Arizona-Rp-Launcher-Beta
chmod +x "Arizona RP Linux Launcher – Lite Edition"
chmod +x "Arizona RP Linux Launcher – Supra Edition"
```

### Запуск

**Lite Edition:**

```bash
./Arizona\ RP\ Linux\ Launcher\ –\ Lite\ Edition
```

**Supra Edition (GUI через Zenity або консольний режим):**

```bash
./Arizona\ RP\ Linux\ Launcher\ –\ Supra\ Edition --debug
```

**Використання реального часу для Supra Edition через FIFO:**

```bash
echo "/info" > ~/.config/arizona_launcher/control.fifo
echo "/restart" > ~/.config/arizona_launcher/control.fifo
```

---

## Переваги

* Розширення аудиторії Linux-гравців
* Автоматичне підключення до серверів без складних налаштувань
* Моніторинг ресурсів та цілісності файлів

---

## Статистика та доказ

* Linux-гравці ≈ 2% від усіх Steam-гравців (\~3,5–4 млн)
* WineHQ AppDB: GTA SA → Gold (працює, є дрібні баги)
* Приклади ігор з Linux-підтримкою: Minecraft, CS\:GO, Dota 2, Rust
