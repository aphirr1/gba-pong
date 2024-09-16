const std = @import("std");

pub const display_control: *volatile DisplayControlConfig = @ptrFromInt(0x0400_0000);
pub const backdrop_color: *volatile Color = @ptrFromInt(0x0500_0000);

pub const keypad: *volatile Keypad = @ptrFromInt(0x400_0130);

pub const timer: *volatile u16 = @ptrFromInt(0x0400_0100);
pub const timerConfig: *volatile TimerConfig = @ptrFromInt(0x0400_0102);

export fn main() void {
    display_control.* = @bitCast(0);

    timerConfig.* = .{
        .timerEnabled = true,
        .freqencyCycles = .@"1",
        .interruptOnOverflow = false,
        .cascadeMode = false,
    };

    while (true) {
        while (timer.* != 0) {}
    }
}

export fn _start() linksection(".text._start") callconv(.Naked) noreturn {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        //
        \\b end_of_header 
        \\.space 0xE0
        \\end_of_header:
        \\ldr r12, =main
        \\bx r12
    );
    while (true) {}
}

// KEYPAD
const KeyState = enum(u1) {
    up = 1,
    down = 0,
};

const Keypad = packed struct(u10) {
    keyA: KeyState,
    keyB: KeyState,
    keySelect: KeyState,
    keyStart: KeyState,
    keyRight: KeyState,
    keyLeft: KeyState,
    keyUp: KeyState,
    keyDown: KeyState,
    keyR: KeyState,
    keyL: KeyState,
};

// COLOR
const Color = packed struct(u16) {
    transparent: bool = false,
    red: u5,
    green: u5,
    blue: u5,

    pub fn initRGB(r: u5, g: u5, b: u5) Color {
        return .{ .red = r, .blue = b, .green = g };
    }
};

// TIMER
const FreqencyCycleConfig = enum(u2) {
    @"1" = 0,
    @"64" = 1,
    @"256" = 2,
    @"1024" = 3,
};

const TimerConfig = packed struct(u8) {
    freqencyCycles: FreqencyCycleConfig,
    cascadeMode: bool,
    __3bit_padding__: u3 = 0,
    interruptOnOverflow: bool,
    timerEnabled: bool,
};

pub const VideoModes = enum(u3) {
    Mode3 = 0,
    Mode4 = 1,
    Mode5 = 2,
};

pub const ObjectMappingModes = enum(u1) {
    @"@2dMapping" = 0,
    @"@1dMapping" = 1,
};

pub const DisplayControlConfig = packed struct(u16) {
    videoMode: VideoModes,
    ///READ ONLY AND BASICALLY USELESS
    isCartridgeGameBoyColor: bool,
    allowOAMAccess: bool,
    objectMappingMode: ObjectMappingModes,
    ///Write this bit to force a screen blank or use 'forceScreenBlank()'
    forceBlankBit: u1,
    renderBackground0Layer: bool,
    renderBackground1Layer: bool,
    renderBackground2Layer: bool,
    renderBackground3Layer: bool,
    renderObjectLayer: bool,
    enableWindow0: bool,
    enableWindow1: bool,
    enableObjectWindow: bool,

    pub fn forceScreenBlank(self: *DisplayControlConfig) void {
        self.forceBlankBit.* = 1;
    }
};
