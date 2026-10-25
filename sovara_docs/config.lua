Config = {}

Config.MaxDistance = 3.0      -- Abstand zwischen beiden Spielern (Meter)
Config.RequestTimeout = 300   -- Sekunden, bis eine offene Unterschrift verfällt
Config.MaxListed = 25         -- so viele Dokumente werden beim Öffnen einer Kopie angezeigt

-- Wer darf welches Dokument ausstellen?
-- Beispiel: Gewerbeschein nur für Job "stadtverwaltung"
function Config.CanIssue(xPlayer, docType)
    if docType == 'gewerbe' then
        return true -- <-- ersetzen durch: xPlayer.job.name == 'stadtverwaltung'
    end
    return true
end

Config.Docs = {
    arbeitsvertrag = { copy = 'arbeitsvertrag_kopie' },
    gewerbe        = { copy = 'gewerbe_kopie' },
}
