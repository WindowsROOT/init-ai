# ตัวอย่างการติดตั้งและใช้งาน Agent Skills

สคริปต์ใน repo นี้ติดตั้ง skills จาก 3 แหล่ง:

| Repo | ลิงก์ |
|------|------|
| Karpathy guidelines | https://github.com/multica-ai/andrej-karpathy-skills |
| Matt Pocock | https://github.com/mattpocock/skills |
| 9arm | https://github.com/thananon/9arm-skills |

## ติดตั้ง

**macOS / Linux:**

```bash
cd /path/to/init-ai

# ติดตั้งทั้งหมด (symlink) ไป Cursor + Claude Code
./scripts/install-skills.sh

# mattpocock ผ่าน skills.sh แล้ว symlink karpathy + 9arm
./scripts/install-skills.sh --method all

# เฉพาะ Cursor + ใส่ Karpathy rule ในโปรเจกต์ปัจจุบัน
./scripts/install-skills.sh --target cursor --project .

# เฉพาะบาง repo
./scripts/install-skills.sh --repos karpathy,9arm

# อัปเดตจาก upstream (pull ใน cache แล้ว re-link)
./scripts/install-skills.sh --update

# ดูว่าจะทำอะไร โดยไม่แตะระบบ
./scripts/install-skills.sh --dry-run
```

**Windows (CMD):** ใช้ flag เดียวกันกับ `install-skills.cmd`

```bat
cd C:\path\to\init-ai
scripts\install-skills.cmd
scripts\install-skills.cmd --method all
scripts\install-skills.cmd --target cursor --project .
scripts\install-skills.cmd --dry-run
```

Cache บน Windows: `%LOCALAPPDATA%\init-ai\skills-cache\`

### ตัวเลือกที่ใช้บ่อย

| Flag | ค่าเริ่มต้น | ความหมาย |
|------|-------------|----------|
| `--target` | `both` | `cursor` \| `claude` \| `both` |
| `--method` | `symlink` | `symlink` \| `npx` \| `all` (เฉพาะ mattpocock) |
| `--repos` | ทั้ง 3 | เช่น `karpathy,mattpocock,9arm` |
| `--project DIR` | — | copy Karpathy rule ไป `DIR/.cursor/rules/` |
| `--update` | off | `git pull` ใน cache |

Cache อยู่ที่ `~/.local/share/init-ai/skills-cache/` (หรือ `$XDG_DATA_HOME/init-ai/skills-cache/`)

## ตรวจว่าติดตั้งแล้ว

```bash
ls -la ~/.cursor/skills | head -20
ls -la ~/.claude/skills | head -20

# นับ SKILL.md ใน cache
find ~/.local/share/init-ai/skills-cache -name SKILL.md | wc -l
```

Skills ที่ติดตั้งด้วย symlink จะชี้ไปที่ cache — อัปเดตด้วย `./scripts/install-skills.sh --update`

## ตัวอย่าง prompt ใน Cursor / Claude Code

Agent โหลด skill เมื่อคำอธิบายใน `SKILL.md` ตรงกับงาน หรือเมื่อคุณอ้างชื่อ skill โดยตรง

### Karpathy (`karpathy-guidelines`)

ไม่ต้องพิมพ์คำสั่งพิเศษถ้ามี user rule หรือ project rule (`.cursor/rules/karpathy-guidelines.mdc`) แล้ว — agent จะยึดหลัก simplicity, surgical changes, ถามก่อนลงมือ

ตัวอย่างเมื่อต้องการเน้นชัด:

```
ช่วย refactor module นี้ตาม karpathy-guidelines — อย่าแตะโค้ดนอก scope
```

### Matt Pocock

หลังติดตั้งด้วย `npx` หรือ symlink ให้รัน **`/setup-matt-pocock-skills`** ครั้งหนึ่งต่อ repo ที่ใช้งาน (ใน Claude Code หรือ agent ที่รองรับ slash commands)

| ต้องการ | ตัวอย่างในแชท |
|---------|----------------|
| จูน requirement ก่อนเขียนโค้ด | `ใช้ skill grill-me ช่วยถามฉันก่อน implement feature X` หรือ `/grill-me` |
| จูน requirement + domain language | `ใช้ grill-with-docs กับแผนนี้` หรือ `/grill-with-docs` |
| TDD | `ทำ feature Y ตาม skill tdd — red-green-refactor` หรือ `/tdd` |
| Debug ยาก | `ใช้ diagnose กับ bug นี้ — reproduce ก่อน` หรือ `/diagnose` |
| แตก issue จาก PRD | `ใช้ to-issues แตก PRD นี้เป็น vertical slices` |
| ปรับสถาปัตยกรรม | `รัน improve-codebase-architecture กับ module Z` |
| สื่อสารสั้น | `ใช้ caveman mode สำหรับคำตอบนี้` |

### 9arm

| ต้องการ | ตัวอย่างในแชท |
|---------|----------------|
| Debug แบบมีวินัย | `ใช้ debug-mantra — reproduce ก่อน แล้ว trace fail path` |
| Review แผน/PR | `scrutinize แผน PR นี้จากมุม outsider` |
| Post-mortem หลัง fix | `เขียน post-mortem หลัง fix bug #123 — ต้องมี root cause และ validation` |
| สื่อสารกับหัวหน้า | `ใช้ management-talk ปรับข้อความนี้ให้เหมาะกับ Slack` |

## Matt Pocock — ขั้นตอนหลังติดตั้ง

1. ติดตั้ง:

   ```bash
   ./scripts/install-skills.sh --method npx --repos mattpocock
   # หรือ
   ./scripts/install-skills.sh --method symlink --repos mattpocock
   ```

2. เปิด agent ใน repo ที่จะใช้ → รัน `/setup-matt-pocock-skills` (เลือก issue tracker, labels, ที่เก็บ docs)

3. ใช้งานตาม workflow เช่น `/grill-me` → `/to-prd` → `/to-issues` → `/tdd`

ถ้า `npx skills add` ล้ม (interactive / network) ให้ลอง:

```bash
npx skills@latest add mattpocock/skills
# หรือ
./scripts/install-skills.sh --method symlink --repos mattpocock
```

## Karpathy rule ในโปรเจกต์ใหม่

```bash
./scripts/install-skills.sh --repos karpathy --target cursor --project ~/Github/my-app
```

จะได้ `my-app/.cursor/rules/karpathy-guidelines.mdc` (always-on ในโปรเจกต์นั้น)

## ชื่อ skill ซ้ำ

ถ้า repo คนละที่มี skill ชื่อเดียวกัน script จะ **ข้าม** ตัวหลังและแจ้ง warning — ลบหรือย้าย symlink เก่าก่อนติดตั้งใหม่ถ้าต้องการเปลี่ยนแหล่ง
