SFX_fire_arrow:   
  db 4,#00,5,#04    ;; frequency
  db 10,#10          ;; volume
  db 11,#00,12,#10  ;; envelope frequency
  db 13 + MUSIC_CMD_TIME_STEP_FLAG,#09         ;; shape of the envelope
;  db 7,#b8          ;; sets channels to wave
  db MUSIC_CMD_SKIP
  db 4,#00,5 + MUSIC_CMD_TIME_STEP_FLAG,#08    ;; frequency
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db 10,#00          ;; silence
  db SFX_CMD_END    


SFX_fire_bullet_enemy:   
  db 4,#00,5,#02    ;; frequency
  db 10,#10          ;; volume
  db 11,#00,12,#10  ;; envelope frequency
  db 13 + MUSIC_CMD_TIME_STEP_FLAG,#09         ;; shape of the envelope
;  db 7,#b8          ;; sets channels to wave
  db MUSIC_CMD_SKIP
  db 4,#00,5,#04    ;; frequency
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP, MUSIC_CMD_SKIP
  db 10,#00          ;; silence
  db SFX_CMD_END    


SFX_sword_swing:
  db  7,#9c    ;; noise in channel C, and tone in channels B and A
  db 10,#0a    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#16    ;; noise frequency
  db 10,#0c    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#14    ;; noise frequency
  db 10,#0f    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#12    ;; noise frequency
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#10    ;; noise frequency
  db 10,#0c    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#08    ;; noise frequency
  db 10,#0a    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#06    ;; noise frequency
  db 10,#08    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#04    ;; noise frequency
  db 10,#06    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#02    ;; noise frequency
  db 10,#04    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#01    ;; noise frequency
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#02    ;; volume
  db 10,#00    ;; silence
  db SFX_CMD_END    


SFX_hit_enemy:
  db  7,#b8    ;; SFX all channels to tone
  db 10,#0f    ;; volume
  db 4,#0, 5 + MUSIC_CMD_TIME_STEP_FLAG,4 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,5 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,6 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,7 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,8 ;; frequency
  db 10,#0d    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,9 ;; frequency
  db 10,#0a    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,10 ;; frequency
  db 10,#00    ;; volume
  db SFX_CMD_END


SFX_hit_deflected:
  db  7,#9c    ;; noise in channel C, and tone in channels B and A
  db 10,#0f    ;; volume
  db  6 + MUSIC_CMD_TIME_STEP_FLAG,#04    ;; noise frequency
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#00    ;; volume
  db MUSIC_CMD_SKIP

  db  6,#01    ;; noise frequency
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0c    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#00    ;; volume
  db MUSIC_CMD_SKIP

  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0a    ;; volume
  db MUSIC_CMD_SKIP
  db  7,#b8    ;; SFX all channels to tone
  db 10,#0c    ;; volume
  db 4,#20, 5 + MUSIC_CMD_TIME_STEP_FLAG,0 ;; frequency
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#00    ;; volume
  db MUSIC_CMD_SKIP

  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0a    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#00    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#08    ;; volume
  db MUSIC_CMD_SKIP
  db 10,#00    ;; volume
  db SFX_CMD_END


SFX_enemy_kill:
  db  7,#b8    ;; SFX all channels to tone

  db 10,#0f    ;; volume
  db 4,0, 5 + MUSIC_CMD_TIME_STEP_FLAG,8 ;; frequency
  db MUSIC_CMD_SKIP
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,6      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0b    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,4      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#08    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,2      ;; frequency
  db MUSIC_CMD_SKIP

  db 10,#0d    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,6 ;; frequency
  db MUSIC_CMD_SKIP
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,4      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#08    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,3      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#06    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,2      ;; frequency
  db MUSIC_CMD_SKIP

  db 10,#0b    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,4 ;; frequency
  db MUSIC_CMD_SKIP
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,3      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#06    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,2      ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#04    ;; volume
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,1      ;; frequency
  db MUSIC_CMD_SKIP

  db 10,#00    ;; silence
  db SFX_CMD_END      


SFX_weapon_switch:
  db  7,#b8    ;; SFX all channels to tone

  db 10,#0f    ;; volume
  db 4,0, 5 + MUSIC_CMD_TIME_STEP_FLAG,#01 ;; frequency
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db 4,#40,5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0d    ;; volume
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0b    ;; volume
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#09    ;; volume
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#07    ;; volume
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#05    ;; volume
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#03    ;; volume
  db 10,#00    ;; silence
  db SFX_CMD_END 


SFX_item_pickup:
  db  7,#b8    ;; SFX all channels to tone
  db 10,#0f    ;; volume
  db 4,#80, 5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db 10,#0d    ;; volume
  db MUSIC_CMD_SKIP

  db 10,#0f    ;; volume
  db 4,#70, 5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0d    ;; volume

  db 10,#0f    ;; volume
  db 4,#60, 5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0d    ;; volume

  db 10,#0f    ;; volume
  db 4,#50, 5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0d    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#0b    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#08    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#06    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#04    ;; volume
  db MUSIC_CMD_SKIP
  db 10 + MUSIC_CMD_TIME_STEP_FLAG,#02    ;; volume
  db MUSIC_CMD_SKIP
  db 10,#00    ;; silence
  db SFX_CMD_END      


SFX_door_open:
  db  7,#b8    ;; SFX all channels to tone
  db 10,#0f    ;; volume
  db 4,#00, 5 + MUSIC_CMD_TIME_STEP_FLAG,#06 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0e    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0d    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0c    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0b    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#0a    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#08    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#07    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#06    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#05    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#04    ;; volume
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#80 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#00    ;; silence
  db SFX_CMD_END      


SFX_hourglass:
  db 7,#b8    ;; SFX all channels to tone
  db 10,#0f    ;; volume
  db 4,#40, 5 + MUSIC_CMD_TIME_STEP_FLAG,#00 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#00    ;; silence
  db SFX_CMD_END      


SFX_playerhit:
  db 7,#b8    ;; SFX all channels to tone
  db 10,#0f    ;; volume
  db 4,#00, 5 + MUSIC_CMD_TIME_STEP_FLAG,#08 ;; frequency
  db MUSIC_CMD_SKIP
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,#04 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,#02 ;; frequency
  db 5 + MUSIC_CMD_TIME_STEP_FLAG,#01 ;; frequency
  db 4,#80, 5 + MUSIC_CMD_TIME_STEP_FLAG, #00 ;; frequency
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#40 ;; frequency
  db 4 + MUSIC_CMD_TIME_STEP_FLAG,#20 ;; frequency
  db MUSIC_CMD_SKIP
  db 10,#00    ;; silence
  db SFX_CMD_END   
