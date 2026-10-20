import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib import font_manager as fm

fm.fontManager.addfont("/usr/share/fonts/truetype/lato/Lato-Medium.ttf")
for f in fm.findSystemFonts():
    if "Lato" in f: fm.fontManager.addfont(f)
plt.rcParams["font.family"] = "Lato"

W, H = 1600, 1190
fig = plt.figure(figsize=(16, 11.9), dpi=150)
ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, W); ax.set_ylim(H, 0); ax.axis("off")
fig.patch.set_facecolor("white")

INK = "#16191F"; QUIET = "#5F6B7A"
GREEN, GREEN_BG = "#7AA116", "#F2F8EC"
TEAL, TEAL_BG = "#00A4A6", "#E8F6F7"
PURPLE, PURPLE_BG = "#8C4FFF", "#F4EFFF"
ORANGE = "#ED7100"; BLUE = "#2E73B8"; PINK = "#C925D1"; RED = "#DD344C"; GRAY = "#879196"

def box(x, y, w, h, ec, fc="white", lw=1.5, ls="-", r=10, z=1):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0,rounding_size={r}",
                 ec=ec, fc=fc, lw=lw, ls=ls, zorder=z))

def text(x, y, s, size=12, color=INK, weight="normal", ha="center", va="center", z=5, style="normal"):
    ax.text(x, y, s, fontsize=size, color=color, fontweight=weight, ha=ha, va=va, zorder=z, fontstyle=style)

def service(x, y, w, h, color, title, sub=None, z=4):
    box(x, y, w, h, color, "white", lw=1.6, z=z)
    ax.add_patch(FancyBboxPatch((x, y), 8, h, boxstyle="round,pad=0,rounding_size=3", ec=color, fc=color, zorder=z+0.1))
    if sub:
        text(x + w/2 + 4, y + h/2 - 9, title, 11.5, weight="bold", z=z+1)
        text(x + w/2 + 4, y + h/2 + 10, sub, 9.5, QUIET, z=z+1)
    else:
        text(x + w/2 + 4, y + h/2, title, 11.5, weight="bold", z=z+1)

def arrow(p1, p2, color=GRAY, ls="-", lw=1.6, both=False, rad=0.0, z=6):
    style = "<|-|>" if both else "-|>"
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle=style, mutation_scale=14, color=color,
                 lw=lw, ls=ls, connectionstyle=f"arc3,rad={rad}", zorder=z, shrinkA=2, shrinkB=2))

def label(x, y, s, size=9.5, color=QUIET, ha="center"):
    ax.text(x, y, s, fontsize=size, color=color, ha=ha, va="center", zorder=8,
            bbox=dict(boxstyle="round,pad=0.25", fc="white", ec="none"))

# Title
text(40, 34, "AWS Terraform Platform: production architecture", 20, weight="bold", ha="left")
text(40, 64, "Everything below is created by Terraform modules in envs/prod  ·  us-east-1  ·  3 Availability Zones", 11.5, QUIET, ha="left")

service(560, 92, 230, 52, GRAY, "Users", "browser / API clients")

box(30, 175, 1540, 935, TEAL, "none", lw=1.6, ls=(0, (6, 4)), r=14, z=0)
text(48, 196, "AWS Region us-east-1", 12, TEAL, weight="bold", ha="left")

VX, VY, VW, VH = 60, 245, 1150, 845
box(VX, VY, VW, VH, PURPLE, "none", lw=1.8, r=12, z=0.5)
text(VX + 18, VY + 22, "VPC 10.20.0.0/16", 12, PURPLE, weight="bold", ha="left")

service(560, 222, 230, 46, PURPLE, "Internet gateway", z=7)
arrow((675, 144), (675, 222), INK)
label(760, 183, "HTTPS 443 / HTTP 80", 9.5, INK)

AZX = [85, 445, 805]; AZW = 340
for x, n in zip(AZX, ["us-east-1a", "us-east-1b", "us-east-1c"]):
    box(x, 290, AZW, 785, GRAY, "none", lw=1.1, ls=(0, (3, 3)), r=10, z=0.6)
    text(x + 14, 306, n, 10.5, QUIET, weight="bold", ha="left")

tiers = [("Public subnet  /24", 325, 245, GREEN, GREEN_BG),
         ("App subnet  /20  (private)", 590, 230, TEAL, TEAL_BG),
         ("Data subnet  /24  (no internet route)", 840, 220, PURPLE, PURPLE_BG)]
for name, y, h, ec, fc in tiers:
    for x in AZX:
        box(x + 12, y, AZW - 24, h, ec, fc, lw=1.2, r=8, z=1)
        text(x + 24, y + 18, name, 9.5, ec, weight="bold", ha="left", z=2)

# ALB spanning the three public subnets
service(110, 360, 1010, 58, ORANGE, "Application Load Balancer", "listeners 80/443  ·  IP target group  ·  health checks  ·  SG: 80/443 from the internet", z=4)
arrow((675, 268), (675, 360), INK)

# NAT on the right of each public subnet, ALB->task path on the left
for x in AZX:
    service(x + 170, 470, 145, 64, GREEN, "NAT gateway", "outbound only")

for x in AZX:
    service(x + 40, 640, 260, 66, ORANGE, "ECS Fargate task", "port 80  ·  0.5 vCPU / 1 GB")
    arrow((x + 100, 418), (x + 100, 640), INK, lw=1.5)
    arrow((x + 242, 640), (x + 242, 534), GREEN, ls=(0, (4, 3)), lw=1.4)
label(AZX[0] + 100, 560, "port 80", 9.5, INK)
label(AZX[0] + 242, 587, "outbound", 9, GREEN)
text(AZX[1] + 170, 760, "ECS service: 3 to 6 tasks, spread across AZs", 9.5, QUIET)

# RDS
service(AZX[0] + 40, 900, 260, 66, BLUE, "RDS PostgreSQL primary", "db.t4g.small  ·  encrypted gp3")
service(AZX[1] + 40, 900, 260, 66, BLUE, "RDS standby (Multi-AZ)", "takes over on failover")
box(AZX[2] + 40, 900, 260, 66, GRAY, "none", lw=1.1, ls=(0, (3, 3)), z=3)
text(AZX[2] + 170, 933, "spare subnet in DB subnet group", 9.5, QUIET)
arrow((AZX[0] + 300, 933), (AZX[1] + 40, 933), BLUE, both=True, lw=1.4)
label((AZX[0] + 300 + AZX[1] + 40) / 2, 915, "sync", 9, BLUE)
arrow((AZX[0] + 170, 706), (AZX[0] + 170, 900), INK, lw=1.5)
label(AZX[0] + 170, 800, "SQL 5432", 9.5, INK)
text(AZX[0] + 170, 1010, "every task connects to the", 9.5, QUIET)
text(AZX[0] + 170, 1028, "primary's DNS endpoint", 9.5, QUIET)

# S3 gateway endpoint straddling the VPC edge
service(1150, 740, 125, 60, TEAL, "S3 gateway", "endpoint", z=7)
arrow((AZX[2] + 300, 680), (1150, 760), TEAL, lw=1.3)

# Regional services
SX, SW = 1300, 250
text(SX, 300, "Regional AWS services", 11, QUIET, weight="bold", ha="left")
service(SX, 330, SW, 64, ORANGE, "Amazon ECR", "images  ·  scan on push")
service(SX, 414, SW, 64, RED, "Secrets Manager", "RDS master password")
service(SX, 498, SW, 64, PINK, "CloudWatch Logs", "container logs + Flow Logs")
service(SX, 740, SW, 64, GREEN, "Amazon S3", "ECR image layers")
arrow((1275, 770), (SX, 772), TEAL, lw=1.3)
# tasks -> services (via NAT)
ax.plot([1210, 1250, 1250], [610, 610, 362], color=GRAY, lw=1.3, zorder=6)
for yy in (362, 446, 530):
    arrow((1250, yy), (SX, yy), GRAY, lw=1.3)
arrow((AZX[2] + 300, 655), (1210, 610), GRAY, lw=1.3)
label(1246, 640, "via NAT", 9, QUIET)

# State bucket
box(SX, 960, SW, 92, GREEN, "white", lw=1.6, z=4)
ax.add_patch(FancyBboxPatch((SX, 960), 8, 92, boxstyle="round,pad=0,rounding_size=3", ec=GREEN, fc=GREEN, zorder=4.1))
text(SX + SW/2 + 4, 982, "S3 state bucket", 11.5, weight="bold")
text(SX + SW/2 + 4, 1004, "Terraform state for dev and prod", 9.5, QUIET)
text(SX + SW/2 + 4, 1022, "versioned  ·  encrypted  ·  use_lockfile", 9.5, QUIET)
text(SX + SW/2 + 4, 1040, "created once by bootstrap/", 9.5, QUIET)

# Notes below the region
text(40, 1140, "Security groups: ALB accepts 80/443 from the internet  ·  tasks accept port 80 from the ALB only  ·  RDS accepts 5432 from the tasks only", 10.5, INK, ha="left")
text(40, 1164, "Dev uses the same modules with cheaper settings: 1 NAT gateway, 1 task, single-AZ RDS.   Solid = request path  ·  dashed green = outbound internet through NAT", 10.5, QUIET, ha="left")

fig.savefig("/root/out.png" if False else __import__("sys").argv[1], dpi=150, facecolor="white")
