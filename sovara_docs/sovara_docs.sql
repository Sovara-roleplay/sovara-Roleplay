-- 1) Tabelle für die gespeicherten Dokumente
CREATE TABLE IF NOT EXISTS `sovara_docs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `doc_type` VARCHAR(32) NOT NULL,
  `issuer` VARCHAR(80) NOT NULL,
  `signer` VARCHAR(80) NOT NULL,
  `data` LONGTEXT NOT NULL,
  `sig` TEXT NOT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `issuer` (`issuer`),
  KEY `signer` (`signer`)
);

-- 2) Items (überschreibt vorhandene Einträge, kein Fehler #1062)
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('arbeitsvertrag',       'Arbeitsvertrag',          1, 0, 1),
('gewerbe',              'Gewerbeschein (leer)',    1, 0, 1),
('arbeitsvertrag_kopie', 'Arbeitsvertrag (Kopie)',  1, 0, 1),
('gewerbe_kopie',        'Gewerbeschein (Kopie)',   1, 0, 1)
ON DUPLICATE KEY UPDATE
  `label` = VALUES(`label`),
  `weight` = VALUES(`weight`),
  `rare` = VALUES(`rare`),
  `can_remove` = VALUES(`can_remove`);
