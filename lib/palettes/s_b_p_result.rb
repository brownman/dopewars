
class SBPResult < ISBPResult
  def blit(screen, offsets)
    @surface.blit(screen, offsets)
  end

  def is_blocking?
    @actionable.is_blocking?
  end

end

