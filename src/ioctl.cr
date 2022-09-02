lib LibC
  TIOCGWINSZ = 0x40087468
  O_EVTONLY  =     0x8000

  struct Winsize
    ws_row : LibC::UShort
    ws_col : LibC::UShort
    ws_xpixel : LibC::UShort
    ws_ypixel : LibC::UShort
  end

  fun ioctl(fd : LibC::Int, request : LibC::ULong, winsize : LibC::Winsize*) : LibC::Int
end
