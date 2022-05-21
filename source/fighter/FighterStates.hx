package fighter;

enum FighterStates {
    IDLE;
    RUN; // running
    WALK; // walking
    JUMP; // jumping (but not off the ground yet)
    AIR; // in air
    LIGHT; // executing a light attack
    HEAVY; // executing a heavy attack
    BLOCK; // executing a block
    PARRY; // executing a parry
    HITSTUNLIGHT; // hit stun caused by light attack
    HITSTUNHEAVY; // hit stun caused by heavy attack
    LIGHTPARRIED; // character's light attack is parried
    HEAVYPARRIED; // character's heavy attack is parried
}