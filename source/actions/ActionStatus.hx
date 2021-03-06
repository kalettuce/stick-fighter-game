package actions;

enum ActionStatus {
    NEUTRAL; // nothing happens
    BLOCKED; // "your" attack hit "their" block
    BLOCK_HIT; // "their" attack hit "your" block
    PARRIED; // "your" attack hit "their" parry
    PARRY_HIT; // "their" attack hit "your" parry
    PARRY_MISS; // tried to parry, but missed it
    INTERRUPTED; // basically means being hit
}