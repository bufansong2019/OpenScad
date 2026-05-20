// J1900 工控主板外壳 — 3D打印参数化设计
// 底壳 + 顶盖分体，免支撑打印
// 顶盖四角螺丝固定 (带内侧衬套)
// 2.5" SSD 可挂顶盖底面

/* ===== [用户参数] ===== */

// --- 主板 ---
board_l   = 170;     // 长 (mm)
board_w   = 170;     // 宽 (mm)
board_t   = 1.6;     // PCB 厚度
margin    = 5;       // 螺丝孔到板边距离

// --- 散热器高度 (从板底面到散热器顶) ---
hsk_h     = 17.5;    // 全高

// --- 2.5" 硬盘 ---
hdd_en    = true;    // 是否装硬盘
hdd_t     = 7;       // 硬盘厚度 (7或9.5mm)

// --- 外壳 ---
wall_t    = 2.4;     // 壁厚
base_t    = 2.4;     // 底板厚
top_t     = 2.0;     // 顶盖厚
stand_h   = 6;       // 铜柱高
stand_r   = 3.5;     // 铜柱外径

// --- 通风 ---
vent_r    = 1.5;
vent_step = 5;

// --- IO 开口余量 ---
io_clr    = 0.4;     // 每边0.2mm

// --- 后墙 IO 开孔 (相对板中心) ---
// RJ45 网口 16×13mm, 离板子右边5.5cm
rj_w      = 16;
rj_h      = 13;
rj_x      = -22;    // 中心X (从外部看右侧, 右边缘离板右边55mm)

// VGA 口 32×15mm, 放在电源旁边
vga_w     = 32;
vga_h     = 15;
vga_x     = 48;     // 中心X (DC右侧约7.5mm间距)

// USB 上下型, 放网口右侧
usb_w     = 17;     // 本体宽 (不算耳朵)
usb_h     = 19;     // 开口高
usb_ear   = 7;      // 耳朵厚
usb_cd    = 30;     // 螺丝耳中心距
usb_len   = 40;     // 全长
usb_x     = -46;    // 中心X (网口右侧约7.5mm间距)

// DC 电源口 10×10mm, 离左侧3.5mm
dc_w      = 10;
dc_h      = 10;
dc_x      = 76.5;   // 中心X (从外部看左侧)

// --- 前墙电源开关 ---
pwr_r     = 8;       // 安装孔径 (16mm)
pwr_x     = 0;       // 左右居中
// pwr_z 在计算段定义, 自动居中

// --- 装配间隙 ---
clr       = 0.5;     // 主板每边

/* ===== [计算] ===== */

inner_l   = board_l + clr * 2;
inner_w   = board_w + clr * 2;
case_l    = inner_l + wall_t * 2;
case_w    = inner_w + wall_t * 2;

// 主板底面 Z
pcb_bot   = base_t + stand_h;
// 散热器顶 Z
hsk_top   = pcb_bot + hsk_h;

// 外壳高度: 散热器顶 + 余量 (硬盘旁置, 不叠高)
case_h    = max(40, hsk_top + 8);
pwr_z     = case_h / 2;  // 开关高度居中

// 主板四角铜柱位
hole_pts  = [
    [margin - board_l/2, margin - board_w/2],
    [board_l - margin - board_l/2, margin - board_w/2],
    [margin - board_l/2, board_w - margin - board_w/2],
    [board_l - margin - board_l/2, board_w - margin - board_w/2],
];

// 顶盖四角螺丝位 — 壁中心 (沿45°对角线)
_diag    = inner_l/2 + wall_t * (sqrt(2)/2 - 0.5);
lid_pos  = [
    [-_diag, -_diag], [ _diag, -_diag],
    [-_diag,  _diag], [ _diag,  _diag],
];

// 2.5" 硬盘螺丝位 (相对盖中心, 标准100×70mm)
hdd_pos  = [
    [-46.5, -31.5], [ 46.5, -31.5],
    [-46.5,  31.5], [ 46.5,  31.5],
];

$fn = 30;
fs = 16;

/* ===== [工具] ===== */

module _rs(w, h, rad) {
    offset(r = rad) square([w - rad*2, h - rad*2], center = true);
}

module _vents(cx, cy, w, d, ht) {
    for (x = [-w/2 + vent_step/2 : vent_step : w/2 - vent_step/2])
        for (y = [-d/2 + vent_step/2 : vent_step : d/2 - vent_step/2])
            translate([cx + x, cy + y, -0.1])
                cylinder(r = vent_r, h = ht + 0.2, $fn = fs);
}

/* ===== [底板] ===== */

module base_plate() {
    difference() {
        linear_extrude(base_t, convexity = 3)
            _rs(case_l, case_w, wall_t);
        for (p = hole_pts)
            translate([p.x, p.y, -0.1])
                cylinder(r = 1.25, h = base_t + 0.2, $fn = fs);
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
        // VGA 口 (排线转接, 略高于板面避让元件)
        translate([vga_x, inner_w/2 + wall_t/2, io_z0 + 5 + vga_h/2])
            cube([vga_w + io_clr, wall_t + 0.2, vga_h + io_clr], center = true);

        // USB 口 (上下型, 网口右侧)
        translate([usb_x, inner_w/2 + wall_t/2, io_z0 + usb_h/2])
            cube([usb_w + io_clr, wall_t + 0.2, usb_h + io_clr], center = true);

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
                cylinder(r = 1.25, h = stand_h + 1, $fn = fs);
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

/* ===== [CPU 区底板通风] ===== */

module cpu_vent() {
    translate([-board_l/6, -board_w/6, 0])
        _vents(0, 0, 60, 60, base_t);
}

/* ===== [底壳] ===== */

module feet() {
    f_h = 2;       // 矮脚垫, 后续可叠加贴脚
    f_r = 6;
    f_in = 8;
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (case_l/2 - f_in), y * (case_w/2 - f_in), -f_h])
            cylinder(r = f_r, h = f_h, $fn = fs);
}

module bottom_case() {
    difference() {
        union() {
            base_plate();
            walls();
            standoffs();
            feet();
        }
        lid_screw_holes();
        cpu_vent();
    }
}

/* ===== [顶盖] ===== */

module top_cover() {
    w = case_l - clr * 2;
    d = case_w - clr * 2;
    difference() {
        linear_extrude(top_t, convexity = 3)
            _rs(w, d, wall_t);

        // 顶盖四角螺丝孔 (M2 沉头)
        for (p = lid_pos)
            translate([p.x, p.y, -0.1])
                cylinder(r = 3.2, h = top_t + 0.2, $fn = fs);

        // 硬盘螺丝孔 (M3 沉头过孔)
        if (hdd_en)
            for (p = hdd_pos)
                translate([p.x, p.y, -0.1])
                    cylinder(r1 = 3.0, r2 = 1.7, h = top_t + 0.2, $fn = fs);
    }
}

/* ===== [渲染] ===== */

color("#555") bottom_case();
color("#888") translate([0, 0, case_h + 8]) top_cover();

// ---- 导出 STL ----
// bottom_case();
// top_cover();
