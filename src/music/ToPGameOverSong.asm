  include "../constants.asm"
  org #0000
ToPGameOverSong:
  db 7,184
  db MUSIC_CMD_SET_INSTRUMENT, MUSIC_INSTRUMENT_WIND, 0
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1, 30
  db 9, 0
  db 10, 0
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1 + MUSIC_CMD_TIME_STEP_FLAG, 32
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1, 33
  db MUSIC_CMD_PLAY_INSTRUMENT_CH2, 18
  db MUSIC_CMD_PLAY_INSTRUMENT_CH3 + MUSIC_CMD_TIME_STEP_FLAG, 13
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1 + MUSIC_CMD_TIME_STEP_FLAG, 32
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1 + MUSIC_CMD_TIME_STEP_FLAG, 28
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1, 30
  db MUSIC_CMD_PLAY_INSTRUMENT_CH2, 22
  db MUSIC_CMD_PLAY_INSTRUMENT_CH3 + MUSIC_CMD_TIME_STEP_FLAG, 9
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1 + MUSIC_CMD_TIME_STEP_FLAG, 32
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1 + MUSIC_CMD_TIME_STEP_FLAG, 28
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_PLAY_INSTRUMENT_CH1, 30
  db MUSIC_CMD_PLAY_INSTRUMENT_CH2, 18
  db MUSIC_CMD_PLAY_INSTRUMENT_CH3 + MUSIC_CMD_TIME_STEP_FLAG, 13
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_SET_INSTRUMENT, MUSIC_INSTRUMENT_SQUARE_WAVE, 0
  db 8, 0
  db 9, 0
  db 10, 0
  db MUSIC_CMD_SKIP
  db MUSIC_CMD_END