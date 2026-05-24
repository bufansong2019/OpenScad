// J1900 工控主板外壳 — 3D打印参数化设计
// 底壳 + 顶盖分体，免支撑打印
// 顶盖四角螺丝固定 (带内侧衬套)

/* ===== [用户参数] ===== */

// --- 主板 ---
board_l   = 170;     // 长 (mm)
board_w   = 170;     // 宽 (mm)
board_t   = 1.6;     // PCB 厚度

// --- 元件最大高度 (从板面起算) ---
hsk_h     = 22;       // 实测 2.2cm

// --- 外壳 ---
wall_t    = 2.4;     // 壁厚
base_t    = 2.4;     // 底板厚
top_t     = 2.0;     // 顶盖厚
stand_h   = 6;       // 铜柱高
stand_r   = 3.5;     // 铜柱外径

// --- 顶盖螺丝柱 ---
boss_r    = 4.0;     // 内角螺丝柱半径
boss_bot  = 26;      // 螺丝柱底部 Z (高于元件顶)

// --- IO 开口余量 ---
io_clr    = 0.4;     // 每边0.2mm

// --- 后墙 IO 开孔 (相对板中心) ---
// RJ45 网口 16×13mm, 离板子右边5.5cm
rj_w      = 16;
rj_h      = 13;
rj_x      = -22;    // 中心X (从外部看右侧, 右边缘离板右边55mm)

// VGA 口 32×14mm (实测), D-sub壳宽16mm
vga_w     = 32;
vga_h     = 14;
vga_body  = 16;     // D-sub 壳宽 (穿墙部分)
vga_cd    = 26;     // 耳朵螺丝孔中心距 (DB15标准)
vga_x     = 48;     // 中心X (DC右侧约7.5mm间距)

// USB 上下型, 放网口右侧
usb_w     = 17;     // 本体宽 (不算耳朵)
usb_h     = 19;     // 开口高
usb_ear   = 7;      // 耳朵厚
usb_cd    = 30;     // 螺丝耳中心距
usb_len   = 40;     // 全长
usb_x     = -55;    // 中心X (右移避开RJ45,墙体留4.8mm)

// DC 电源口 10×10mm, 离左侧3.5mm
dc_w      = 10;
dc_h      = 10;
dc_x      = 76.5;   // 中心X (从外部看左侧)

// --- 前墙电源开关 ---
pwr_r     = 8;       // 安装孔径 (16mm)
pwr_x     = 0;       // 左右居中
// pwr_z 在计算段定义, 自动居中

// --- 装配间隙 ---
clr       = 1;       // 主板每边间隙

/* ===== [计算] ===== */

inner_l   = board_l + clr * 2;
inner_w   = board_w + clr * 2;
case_l    = inner_l + wall_t * 2;
case_w    = inner_w + wall_t * 2;

// 主板底面 Z
pcb_bot   = base_t + stand_h;
// 散热器顶 Z
hsk_top   = pcb_bot + hsk_h;

// 外壳高度: 最高元件 + 顶部余量
case_h    = max(40, hsk_top + 8);
pwr_z     = case_h / 2;  // 开关高度居中

// 主板四角铜柱位
hole_pts  = [
    // 左下 (孔边缘距左4mm 距底3mm → 中心+2mm)
    [-85 + 6, -85 + 5],
    // 右下 (孔边缘距右4mm 距底3mm)
    [85 - 6, -85 + 5],
    // 左上 (孔边缘距左4mm 距顶8mm)
    [-85 + 6, 85 - 10],
    // 右上 (孔边缘距右4mm 距顶30mm)
    [85 - 6, 85 - 32],
];

// 四角螺丝柱心 (紧贴外壁, 最大体积)
_pillar_d = case_l/2 - boss_r * (sqrt(2)/2);
// 顶盖螺丝孔位 (往柱子中心偏移, 避免薄壁)
_screw_d  = _pillar_d - 1.4;
lid_pos  = [
    [-_screw_d, -_screw_d], [ _screw_d, -_screw_d],
    [-_screw_d,  _screw_d], [ _screw_d,  _screw_d],
];

$fn = 30;
fs = 16;

/* ===== [工具] ===== */

module _rs(w, h, rad) {
    offset(r = rad) square([w - rad*2, h - rad*2], center = true);
}

/* ===== [底板] ===== */

module base_plate() {
    difference() {
        linear_extrude(base_t, convexity = 3)
            _rs(case_l, case_w, wall_t);
        for (p = hole_pts)
            translate([p.x, p.y, -0.1])
                cylinder(r = 1.6, h = base_t + 0.2, $fn = fs);   // M3 过孔 (φ3.2)
    }
}

/* ===== [圆角斜通风槽] ===== */

slot_ang = 12;     // 倾斜角 (°)
slot_len = 25;     // 单节长度 (mm)
slot_h   = 2;      // 缝隙高 (mm)
slot_ys  = 15;     // 列距
slot_yr  = 40;     // Y 覆盖半宽
slot_zs  = 8;      // 行距
slot_nr  = 4;      // 行数
slot_z0  = (case_h - (slot_nr - 1) * slot_zs) / 2;  // 居中起始 Z

module _slot() {
    hull() {
        translate([0, -slot_len/2, 0])
            rotate([0, 90, 0])
                cylinder(r = slot_h/2, h = wall_t + 0.2, center = true, $fn = fs);
        translate([0, slot_len/2, 0])
            rotate([0, 90, 0])
                cylinder(r = slot_h/2, h = wall_t + 0.2, center = true, $fn = fs);
    }
}

/* ===== [四角螺丝柱] ===== */

module corner_bosses() {
    h = case_h - boss_bot;
    for (sx = [-1, 1], sy = [-1, 1])
        intersection() {
            translate([sx * _pillar_d, sy * _pillar_d, boss_bot])
                cylinder(r = boss_r, h = h, $fn = fs);
            // 保留内侧, 外面切掉 (微宽0.2mm确保union)
            translate([0, 0, boss_bot + h/2])
                cube([inner_l + 0.2, inner_w + 0.2, h], center = true);
        }
}

/* ===== [四壁] ===== */

module walls() {
    // IO 开口底部 = 主板上表面 (板底8.4 + 板厚1.6)
    io_z0 = pcb_bot + board_t;

    difference() {
        linear_extrude(case_h, convexity = 4)
            difference() {
                _rs(case_l, case_w, wall_t);
                _rs(inner_l, inner_w, wall_t);
            }

        // ---- 后墙 IO 开口 (Y+) ----
        // 开口在壁中心: inner_w/2 + wall_t/2
        // DC 电源口
        translate([dc_x, inner_w/2 + wall_t/2, io_z0 + dc_h/2])
            cube([dc_w + io_clr, wall_t + 0.2, dc_h + io_clr], center = true);
        // RJ45 网口
        translate([rj_x, inner_w/2 + wall_t/2, io_z0 + rj_h/2])
            cube([rj_w + io_clr, wall_t + 0.2, rj_h + io_clr], center = true);
        // VGA 口 (排线转接, 仅 D-sub 壳穿墙, 耳朵贴内壁锁螺丝)
        translate([vga_x, inner_w/2 + wall_t/2, io_z0 + 5 + vga_h/2])
            cube([vga_body + io_clr, wall_t + 0.2, vga_h + io_clr], center = true);
        // VGA 耳朵穿墙孔 (φ5.5 硬塞六角螺柱)
        for (dx = [-1, 1])
            translate([vga_x + dx * vga_cd/2, inner_w/2 + wall_t/2, io_z0 + 5 + vga_h/2])
                rotate([90, 0, 0])
                    cylinder(r = 2.75, h = wall_t + 0.2, center = true, $fn = fs);

        // USB 口 (上下型, 网口右侧)
        translate([usb_x, inner_w/2 + wall_t/2, io_z0 + usb_h/2])
            cube([usb_w + io_clr, wall_t + 0.2, usb_h + io_clr], center = true);
        // USB 耳朵 M3 固定孔 (φ3.4 过孔, 耳朵贴内壁)
        for (dx = [-1, 1])
            translate([usb_x + dx * usb_cd/2, inner_w/2 + wall_t/2, io_z0 + usb_h/2])
                rotate([90, 0, 0])
                    cylinder(r = 1.7, h = wall_t + 0.2, center = true, $fn = fs);

        // ---- 前墙电源开关 (Y-) ----
        // φ16 通孔
        translate([pwr_x, -(inner_w/2 + wall_t/2), pwr_z])
            rotate([90, 0, 0])
                cylinder(r = pwr_r, h = wall_t + 0.2, center = true, $fn = fs);

        // 斜通风槽 / / / / (左)   \ \ \ \ (右)
        for (y = [-slot_yr : slot_ys : slot_yr])
            for (i = [0 : slot_nr - 1])
                for (s = [-1, 1]) {
                    z = slot_z0 + i * slot_zs;
                    translate([s * (case_l/2 - 1.2), y, z])
                        rotate([s * slot_ang, 0, 0])
                            _slot();
                }
    }
}

module standoffs() {
    for (p = hole_pts)
        translate([p.x, p.y, base_t]) {
            difference() {
                union() {
                    cylinder(r = stand_r, h = stand_h, $fn = fs);
                    cylinder(r = stand_r + 0.8, h = 1.5, $fn = fs);
                }
                cylinder(r = 1.6, h = stand_h + 1, $fn = fs);   // M3 过孔 (φ3.2)
            }
        }
}

/* ===== [顶盖螺丝孔] ===== */

module lid_screw_holes() {
    // M2 自攻 (1.6mm底孔, r=0.8) — 每边剩0.4mm, 推荐
    // M3 自攻 (2.0mm底孔, r=1.0) — 每边剩0.2mm, 需要打印质量好
    _r = 0.8;  // 改 r=1.0 切 M3
    _d = 8;    // 吃料深度 (mm)
    for (p = lid_pos)
        translate([p.x, p.y, case_h - _d])
            cylinder(r = _r, h = _d + 4, $fn = fs);
}

/* ===== [水平通风槽（顶盖/底板用）] ===== */

module _slot_flat(ht) {
    hull() {
        translate([-slot_len/2, 0, -0.1])
            cylinder(r = slot_h/2, h = ht + 0.2, $fn = fs);
        translate([slot_len/2, 0, -0.1])
            cylinder(r = slot_h/2, h = ht + 0.2, $fn = fs);
    }
}

module cpu_vent_slots(ht) {
    // CPU区域通风槽 — 跟侧壁一样: 长边15mm间距, 短边8mm间距
    for (x = [-20 : slot_ys : 25])
        for (y = [-28 : slot_zs : 28])
            translate([25 + x, -5 + y, 0])
                rotate(slot_ang)
                    _slot_flat(ht);
}

/* ===== [底壳] ===== */

module bottom_case() {
    difference() {
        union() {
            base_plate();
            walls();
            standoffs();
            corner_bosses();
        }
        lid_screw_holes();
        cpu_vent_slots(base_t);
    }
}

/* ===== [顶盖] ===== */

module top_cover() {
    w = case_l;
    d = case_w;
    difference() {
        linear_extrude(top_t, convexity = 3)
            _rs(w, d, wall_t);

        // 顶盖四角螺丝孔 (M2 沉头, 锥孔)
        for (p = lid_pos)
            translate([p.x, p.y, -0.1])
                cylinder(r1 = 1.1, r2 = 2.0, h = top_t + 0.2, $fn = fs);

        // CPU区域通风槽
        cpu_vent_slots(top_t);
    }
}

/* ===== [导出 STL] ===== */
// 改下面这个值: "bottom" 或 "top"
_export = "bottom";

if (_export == "bottom") bottom_case();
if (_export == "top") top_cover();
