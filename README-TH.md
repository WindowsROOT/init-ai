# init-ai

เครื่องมือ bootstrap สำหรับ AI coding agent — ติดตั้ง **agent skills** จากชุมชนเข้า Cursor และ Claude Code ด้วยสคริปต์เดียว

[English README](README.md)

## สิ่งที่ต้องมี

- `git`
- **macOS / Linux:** `bash`
- **Windows:** Command Prompt + `git` บน PATH
- `npx` (Node.js) — ใช้เมื่อติดตั้ง [mattpocock/skills](https://github.com/mattpocock/skills) ด้วย `--method npx` หรือ `--method all`

## เริ่มใช้งาน

**macOS / Linux:**

```bash
git clone https://github.com/YOUR_USER/init-ai.git
cd init-ai
./scripts/install-skills.sh
```

**Windows (CMD):**

```bat
git clone https://github.com/YOUR_USER/init-ai.git
cd init-ai
scripts\install-skills.cmd
```

บน Windows จะพยายามสร้าง junction (`mklink /J`) ก่อน ถ้าไม่ได้จะ copy โฟลเดอร์ skill แทน

สคริปต์จะ clone repo ต้นทาง 3 แห่งไปที่ `~/.local/share/init-ai/skills-cache/` แล้ว symlink skills ที่พร้อมใช้งานไปยัง:

- `~/.cursor/skills/` (Cursor)
- `~/.claude/skills/` (Claude Code)

## แหล่ง skills

| คีย์ | Repository |
|------|------------|
| `karpathy` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| `mattpocock` | [mattpocock/skills](https://github.com/mattpocock/skills/) |
| `9arm` | [thananon/9arm-skills](https://github.com/thananon/9arm-skills) |

## แนะนำแต่ละชุด: ใช้ vs ไม่ใช้ต่างกันยังไง

ทั้งสามชุดไม่ได้แทนที่กัน — ทำงานคนละชั้น ติดตั้งทีละชุดหรือรวมก็ได้ (`--repos karpathy` ฯลฯ)

### 1. [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) — กฎพฤติกรรม (ทุกงาน)

**คืออะไร:** หลักการ 4 ข้อจาก Andrej Karpathy — คิดก่อนเขียนโค้ด, ทำให้เรียบที่สุด, แก้เฉพาะที่จำเป็น, มีเกณฑ์สำเร็จที่วัดได้

| | **ใช้** | **ไม่ใช้** |
|---|--------|-----------|
| **ผลที่ได้** | diff เล็กลง, ถามก่อนเดา, ลดโค้ดฟุ่มเฟือยและ refactor นอก scope | agent มัก “ทำเกิน”: แก้ไฟล์รอบข้าง, สร้าง abstraction ใหญ่, สมมติ requirement เอง |
| **เหมาะเมื่อ** | ใช้ agent เขียน/แก้โค้ดบ่อย ทุกโปรเจกต์ | งานสั้นมากที่ยอมรับ diff กว้างได้ |
| **ใน Cursor** | skill + (แนะนำ) rule ในโปรเจกต์: `--project .` | ไม่มี guardrail — พึ่ง prompt ทีละครั้ง |
| **ติดตั้ง** | `./scripts/install-skills.sh --repos karpathy` | — |

**สรุป:** ชุดนี้เหมือน “มาตรฐานวิศวกร” ติดตั้งครั้งเดียวแล้วได้ผลตลอด ไม่ต้องเรียก slash command

---

### 2. [mattpocock/skills](https://github.com/mattpocock/skills/) — workflow วิศวกรรม (ตามงาน)

**คืออะไร:** skills เป็นขั้นตอนเฉพาะ — สอบ requirement, TDD, debug, แตก issue, ปรับสถาปัตยกรรม, สื่อสารสั้น ฯลฯ

| | **ใช้** | **ไม่ใช้** |
|---|--------|-----------|
| **ผลที่ได้** | งานใหญ่มีลำดับชัด: ถามจนเข้าใจ → แผน/PRD → issue → red-green-refactor | ได้โค้ดเร็วแต่มัก misalign, test ไม่ครบ, debug วนเดา |
| **เหมาะเมื่อ** | feature ใหม่, refactor ใหญ่, ทีมใช้ issue tracker | spike ทิ้งๆ หรืองาน one-liner |
| **ต้อง setup** | ครั้งแรกต่อ repo: `/setup-matt-pocock-skills` | — |
| **ติดตั้ง** | `--repos mattpocock` หรือ `--method npx` (official ผ่าน skills.sh) | — |

**skills ที่คุ้มสุด:**

- `/grill-me` / `/grill-with-docs` — ก่อนลงมือ implement
- `/tdd` — feature/bug ที่ต้องการ test จริง
- `/diagnose` — bug ยาก / performance
- `/to-issues`, `/to-prd` — แตกงานจากแผน
- `/improve-codebase-architecture` — codebase เริ่มเลอะ

**สรุป:** ไม่ได้แทน Karpathy — Karpathy บอก “อย่าทำมั่ว” Matt บอก “ทำงานนี้ตามขั้นตอนไหน”

---

### 3. [9arm-skills](https://github.com/thananon/9arm-skills) — วินัย debug / review / สื่อสาร

**คืออะไร:** ชุดเล็กจาก workflow จริงของทีม — เน้น reproduce, review แบบ outsider, post-mortem, เขียนถึงหัวหน้า

| | **ใช้** | **ไม่ใช้** |
|---|--------|-----------|
| **ผลที่ได้** | debug เป็นระบบ, review จับช่องโหว่ในแผน, บันทึกหลัง incident ชัด | แก้ bug แบบลองผิดลองถูก, PR review ตื้น, สื่อสารวิศวกร→เมเนเจอร์ยาวและไม่ตรง channel |
| **เหมาะเมื่อ** | production bug, post-incident, review ก่อน merge สำคัญ | โปรเจกต์เล็กที่ไม่มี incident process |
| **skills หลัก** | `debug-mantra`, `scrutinize`, `post-mortem`, `management-talk` | — |
| **ติดตั้ง** | `./scripts/install-skills.sh --repos 9arm` | — |

**สรุป:** เสริม Matt/Karpathy ตอน **คุณภาพและความถูกต้อง** มากกว่าตอนเริ่ม feature

---

### เลือกติดตั้งอย่างไร

| สถานการณ์ | แนะนำ |
|-----------|--------|
| เริ่มใช้ agent ทุกวัน | **karpathy** ก่อน (พื้นฐาน) |
| ทำ product / feature ยาว | **karpathy** + **mattpocock** |
| ดูแล production / ทีมมี review | ครบทั้ง 3 |
| อยากเบา | `--repos karpathy,9arm` (ไม่ต้อง setup Matt) |
| อยาก workflow Matt แบบ official | `--method all` สำหรับ mattpocock |

```bash
# เฉพาะกฎพฤติกรรม
./scripts/install-skills.sh --repos karpathy --project .

# workflow วิศวกรรม + debug/review
./scripts/install-skills.sh --repos mattpocock,9arm
```

## คำสั่งที่ใช้บ่อย

```bash
# ค่าเริ่มต้น: ทั้ง 3 repo, symlink, cursor + claude
./scripts/install-skills.sh

# Matt Pocock ผ่าน skills.sh + symlink ที่เหลือ
./scripts/install-skills.sh --method all

# Karpathy rule ในโปรเจกต์ปัจจุบัน
./scripts/install-skills.sh --repos karpathy --target cursor --project .

# เลือกบาง repo + อัปเดต cache
./scripts/install-skills.sh --repos 9arm,mattpocock --update

./scripts/install-skills.sh --help
```

**หลังติดตั้ง (Matt Pocock):** รัน `/setup-matt-pocock-skills` ครั้งหนึ่งต่อโปรเจกต์ จากนั้นใช้ skills เช่น `/grill-me`, `/tdd`, `/diagnose`

ดู **[EXAMPLES.md](EXAMPLES.md)** สำหรับตัวอย่าง prompt และการแก้ปัญหา (ภาษาไทย)

## ตัวเลือก

| Flag | ค่าเริ่มต้น | ความหมาย |
|------|-------------|----------|
| `--target` | `both` | `cursor`, `claude`, หรือ `both` |
| `--method` | `symlink` | `symlink`, `npx`, หรือ `all` (npx ใช้กับ mattpocock เท่านั้น) |
| `--repos` | ทั้ง 3 | คั่นด้วย comma: `karpathy,mattpocock,9arm` |
| `--project DIR` | — | copy Karpathy rule `.mdc` ไป `DIR/.cursor/rules/` |
| `--dry-run` | ปิด | แสดง action โดยไม่แก้ระบบ |
| `--update` | ปิด | `git pull --ff-only` ใน cache แล้ว link ใหม่ |

## หมายเหตุ

- **ติดตั้งแบบ symlink** ชี้ไปที่ cache — ใช้ `--update` เพื่อดึงเวอร์ชันล่าสุดจาก upstream
- **ชื่อ skill ซ้ำ:** ถ้า `~/.cursor/skills/foo` เป็นโฟลเดอร์จริงอยู่แล้ว (ไม่ใช่ symlink) สคริปต์จะข้ามและแจ้ง warning แทนการทับ
- **Karpathy ใน Claude Code** ติดตั้งผ่าน [plugin marketplace](https://github.com/multica-ai/andrej-karpathy-skills#install) ได้ตาม README ต้นทาง

## โครงสร้างไฟล์

```
scripts/
  install-skills.sh      # macOS / Linux
  install-skills.cmd     # Windows
  lib/skills-common.sh   # logic สำหรับ .sh
EXAMPLES.md              # ตัวอย่างการใช้งาน
```
