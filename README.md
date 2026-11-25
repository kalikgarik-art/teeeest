# Obby — паркур с чекпоинтами (Rojo + Luau)

Простая игра в жанре **Obby**: стартовый спавн, 10 цветных платформ-чекпоинтов,
красные блоки-ловушки (killbricks), финишная платформа и таблица лидеров со
статусом `Stage`. Весь уровень генерируется сервером при запуске через
`Instance.new("Part")` — внешних 3D-моделей и платных ассетов нет.

Проект собран по стандартной структуре **Rojo 7+** и полностью написан на
современном **Luau** со строгой типизацией (`--!strict`).

---

## Структура репозитория

```text
.
├── default.project.json      # Маппинг папок src/ в сервисы Roblox (Rojo)
├── README.md
├── .gitignore                # Игнор для Rojo/Roblox (в т.ч. *.rbxl, *.rbxlx)
└── src/
    ├── shared/               # → ReplicatedStorage/ObbyShared (Folder)
    │   ├── Config.luau       # Общие константы: число этапов, FALL_Y, палитра…
    │   ├── Types.luau        # Общие типы Luau (LevelData, CheckpointData, Remotes)
    │   └── Remotes.luau      # Доступ к RemoteEvent'ам ObbyRemotes
    ├── server/               # → ServerScriptService/ObbyServer (Script)
    │   ├── init.server.luau  # Точка входа сервера
    │   └── Obby/
    │       ├── LevelGenerator.luau    # Процедурная генерация уровня
    │       ├── PlayerService.luau     # Leaderstats, респавн, падение ниже Y=-50
    │       ├── CheckpointService.luau # Чекпоинты по порядку + финиш
    │       └── KillbrickService.luau  # Красные блоки-убийцы
    └── client/               # → StarterPlayer/StarterPlayerScripts/ObbyClient (LocalScript)
        ├── init.client.luau  # Точка входа клиента
        ├── FinishGui.luau    # Экран поздравления с кнопкой «Начать заново»
        └── StageHud.luau     # Подсказка «Этап: X / 10» сверху экрана
```

Как работает маппинг Rojo:

| Путь в репозитории | Instance в плейсе |
| --- | --- |
| `src/server/` (`init.server.luau`) | `ServerScriptService/ObbyServer` (Script) |
| `src/client/` (`init.client.luau`) | `StarterPlayer/StarterPlayerScripts/ObbyClient` (LocalScript) |
| `src/shared/` | `ReplicatedStorage/ObbyShared` (Folder с ModuleScript'ами) |
| объявлено в `default.project.json` | `ReplicatedStorage/ObbyRemotes` (Folder с `PlayerFinished`, `RestartRequested`) |

Папки без `init.*.luau` Rojo превращает в обычные `Folder`, файлы
`*.server.luau` — в `Script`, `*.client.luau` — в `LocalScript`,
остальные `*.luau` — в `ModuleScript`.

---

## Игровая механика (MVP)

1. **Leaderstats.** При входе каждому игроку создаётся `leaderstats` со
   значением `Stage = 1`. Чекпоинт с номером `i` показывает `Stage = i`
   (стартовая площадка и первый чекпоинт оба показывают `1` — точная позиция
   респавна хранится отдельно как индекс чекпоинта: `0` — старт, `1..10` —
   чекпоинты).
2. **Процедурный уровень.** Сервер при старте генерирует: стартовую площадку
   (`SpawnLocation`), 10 платформ-чекпоинтов разного цвета и размера
   (фиксированный `Random` seed — уровень одинаковый на каждом запуске) и
   золотую финишную платформу. На каждой платформе — табличка с номером этапа.
3. **Чекпоинты и респавн.** Касание платформы следующего по порядку этапа
   обновляет `Stage` и записывает платформу в `Player.RespawnLocation`
   (платформы — это `SpawnLocation`, поэтому смерть от killbrick'а сразу
   респавнит игрока на текущем чекпоинте). Серверный цикл каждые 0.1 с
   проверяет `HumanoidRootPart.Position.Y < -50` и телепортирует упавшего
   игрока обратно на его текущий чекпоинт.
4. **Killbricks.** Между каждой парой платформ (старт → 1 → … → 10 → финиш)
   под траекторией прыжка висит красный неоновый блок. Касание убивает
   персонажа (`Humanoid.Health = 0`).
5. **Финиш.** Касание финишной платформы после 10-го этапа шлёт клиенту
   `PlayerFinished`, и на экране (через `PlayerGui`, который Roblox заполняет
   из `StarterGui`) появляется панель «Поздравляем! Вы прошли все 10 этапов!»
   с кнопкой **«Начать заново»**. Кнопка шлёт `RestartRequested` на сервер:
   `Stage` сбрасывается на 1, респавн — на старт, игрок телепортируется на
   стартовую площадку.

Управление — стандартное: `WASD` — движение, `Space` — прыжок.

---

## Быстрый старт

### 1. Клонировать репозиторий

```bash
git clone https://github.com/kalikgarik-art/teeeest.git
cd teeeest
```

### 2. Установить Rojo (7+)

Любой удобный способ:

```bash
# через Cargo (https://doc.rust-lang.org/cargo/)
cargo install rojo

# через npm
npm install -g rojo-rbx

# через Scoop (Windows)
scoop install rojo

# через Homebrew (macOS)
brew install rojo
```

Проверка:

```bash
rojo --version   # должен показать 7.x
```

### 3. Вариант А — синхронизация со Studio через плагин (рекомендуется)

1. Установите плагин Rojo в Roblox Studio: **Plugins → Manage Plugins →
   Rojo** (или скачайте `.rbxm` плагин с
   [GitHub Releases Rojo](https://github.com/rojo-rbx/rojo/releases)).
2. В терминале запустите Rojo-сервер из корня проекта:

   ```bash
   rojo serve
   ```

   Rojo поднимет локальный сервер (по умолчанию `http://localhost:34872`).
3. В Roblox Studio откройте плагин Rojo и нажмите **Connect**.
   Плагин синхронизирует дерево из `default.project.json` в открытый плейс.
4. Нажмите **Play** (F5) — уровень сгенерируется сервером при старте.

> Чтобы синхронизировать в пустой плейс, откройте в Studio любой базовый
> плейс (например, **Baseplate**) — Rojo добавит недостающие сервисы и скрипты.
> Сгенерированный уровень появится в `Workspace/ObbyLevel` только после Play.

### 4. Вариант Б — собрать `.rbxl` и открыть в Studio

```bash
rojo build default.project.json -o obby.rbxl
```

Откройте `obby.rbxl` в Roblox Studio и нажмите **Play**. Собранный файл
находится в `.gitignore` и в репозиторий не коммитится — он всегда
пересобирается из исходников.

---

## Разработка

- Весь код — Luau с `--!strict` в первой строке каждого файла. Типы уровня
  (`LevelData`, `CheckpointData`) и RemoteEvent'ов (`Remotes`) лежат в
  `src/shared/Types.luau`.
- Общие константы (число этапов, `FALL_Y = -50`, размеры, палитра) — в
  `src/shared/Config.luau`. Чтобы поменять длину курса, достаточно изменить
  `STAGE_COUNT` и добавить цвет в `PALETTE`.
- Серверная логика разделена на сервисы с `Init(...)`: `PlayerService`
  (leaderstats/респавн), `CheckpointService` (чекпоинты/финиш),
  `KillbrickService` (ловушки). `init.server.luau` только связывает их вместе.
- Клиентский GUI строится кодом (`FinishGui`, `StageHud`) и кладётся в
  `PlayerGui` — в плейс-файле GUI-инстансов нет, всё пересоздаётся из кода.
- RemoteEvent'ы объявлены в `default.project.json`
  (`ReplicatedStorage/ObbyRemotes`). Если плейс открыт без Rojo-синка,
  сервер создаёт их сам при старте (`src/shared/Remotes.luau`).

### Проверка в Studio

1. `rojo serve` + Connect (или откройте собранный `obby.rbxl`).
2. Play → вы спавнитесь на серой стартовой площадке, `Stage = 1`.
3. Пройдите платформы по порядку — `Stage` растёт, HUD сверху показывает
   «Этап: X / 10».
4. Упадите в пустоту — телепорт обратно на текущий чекпоинт.
5. Коснитесь красного блока — смерть и респавн на текущем чекпоинте.
6. Дойдите до золотой платформы «FINISH» — панель поздравления и кнопка
   «Начать заново».

---

## Лицензия

Учебный проект. Свободное использование и модификация разрешены.
