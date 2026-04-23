/// User-visible pipeline positions for the progress UI (maps to `docs` flow, not 1:1 to HTTP calls).
enum ProfessionPipelineStage {
  idle,
  inputReady,
  creatingProfession,
  generatingSituations,
  choosingSituation,
  generatingImage,
  savingResult,
  done,
  error,
}

/// Telegram link flow: parse → briefs (same server batch) → image.
enum TelegramPipelineStage {
  idle,
  inputReady,
  fetchingInsights,
  creatingProfession,
  generatingSituations,
  generatingImage,
  savingResult,
  done,
  error,
}
