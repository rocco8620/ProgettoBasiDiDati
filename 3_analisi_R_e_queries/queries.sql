-- NOTA: Le seguenti queries sono le stesse presenti nella relazione, in un formato più adatto per fare copia e incolla.

--- QUERIES DI DIMOSTRAZIONE ---

-- 1. Aggiunta di un concerto

INSERT INTO Concerto (
  nome, numero_posti, prezzo, data, ora, nome_ambiente,
  indirizzo, nome_citta, cap_citta, genere
) VALUES (
  'J.Fisher - The return', 100, 20.00, '2023-10-15', '20:00:00', 'us Arena',
  '60242 Plainschester, Norfolk, Texas 72264', 'Plano', '18016', 'Pop'
);

INSERT INTO Ingaggio_Artista (
  data_concerto, ora_concerto, nome_ambiente, indirizzo_ambiente,
  nome_citta, cap_citta, artista
) VALUES (
  '2023-10-15', '20:00:00', 'us Arena', '60242 Plainschester, Norfolk, Texas 72264',
  'Plano', '18016', 'Jaquelin Fisher'
);

-- 2. Acquisto di un biglietto

INSERT INTO Persona (
  CF, nome, cognome, email, indirizzo,
  metodo_pagamento
) VALUES (
  'ABCDEF12G34H567I', 'Mario', 'Rossi', 'mario.rossi@gmail.com', 'Via Udine 1, Milano',
  '5338 5689 5214 4568'
);

INSERT INTO Biglietto (
  proprietario, venditore, data_vendita, ora_vendita, data_concerto,
  ora_concerto, nome_ambiente, indirizzo_ambiente, nome_citta, cap_citta
) VALUES (
  'ABCDEF12G34H567I', 'Equifax SpA', '2023-10-01', '10:00:00', '2023-10-15',
  '20:00:00', 'us Arena', '60242 Plainschester, Norfolk, Texas 72264', 'Plano', '18016'
);

-- 1. Cancellazione di un biglietto

DELETE FROM Biglietto WHERE id = 1;

-- 1. Stabilire il numero di biglietti venduti e disponibili

SELECT
  numero_biglietti_venduti,
  (numero_posti - numero_biglietti_venduti) AS biglietti_disponibili
FROM Concerto
WHERE     data = '2023-10-15'
      AND ora = '20:00:00'
      AND nome_ambiente = 'us Arena'
      AND indirizzo = '60242 Plainschester, Norfolk, Texas 72264'
      AND nome_citta = 'Plano'
      AND cap_citta = '18016';

-- 2. Stabilire quanti biglietti sono stati venduti da una specifica agenzia per un concerto

SELECT COUNT(*) AS biglietti_venduti
FROM Biglietto
WHERE     venditore = 'Equifax SpA'
      AND data_concerto = '2023-10-15'
      AND ora_concerto = '20:00:00'
      AND nome_ambiente = 'us Arena'
      AND indirizzo_ambiente = '60242 Plainschester, Norfolk, Texas 72264'
      AND nome_citta = 'Plano'
      AND cap_citta = '18016';

-- 3. Percentuale di agenzie che hanno effettivamente venduto almeno un biglietto per un dato concerto

SELECT COUNT(DISTINCT b.venditore) / COUNT(DISTINCT dp.agenzia) * 100 AS percentuale_agenzie_attive
FROM Diritto_Prevendita dp
JOIN Concerto c ON dp.genere = c.genere
LEFT JOIN Biglietto b ON
  b.data_concerto = c.data AND
  b.ora_concerto = c.ora AND
  b.nome_ambiente = c.nome_ambiente AND
  b.indirizzo_ambiente = c.indirizzo AND
  b.nome_citta = c.nome_citta AND
  b.cap_citta = c.cap_citta AND
  b.venditore = dp.agenzia
WHERE
  c.data = '2020-08-28' AND
  c.ora = '22:00:00' AND
  c.nome_ambiente = 'world Arena' AND
  c.indirizzo = '1529 Ovalchester, San Jose, New Mexico 79549' AND
  c.nome_citta = 'St. Paul' AND
  c.cap_citta = '86216';

-- 4. Lista delle città in cui si è esibito un artista

SELECT DISTINCT
  c.nome_citta,
  c.cap_citta
FROM Concerto c
-- Esibizioni da solista
WHERE EXISTS (
  SELECT *
  FROM Ingaggio_Artista ia
  WHERE
    ia.artista = 'NomeArtista' AND
    ia.data_concerto = c.data AND
    ia.ora_concerto = c.ora AND
    ia.nome_ambiente = c.nome_ambiente AND
    ia.indirizzo_ambiente = c.indirizzo AND
    ia.nome_citta = c.nome_citta AND
    ia.cap_citta = c.cap_citta
)
-- Oppure esibizioni tramite un gruppo
OR EXISTS (
  SELECT *
  FROM Ingaggio_Gruppo ig
  JOIN Artista_In_Gruppo aig ON ig.gruppo = aig.gruppo
  WHERE
    aig.artista = 'NomeArtista' AND
    ig.data_concerto = c.data AND
    ig.ora_concerto = c.ora AND
    ig.nome_ambiente = c.nome_ambiente AND
    ig.indirizzo_ambiente = c.indirizzo AND
    ig.nome_citta = c.nome_citta AND
    ig.cap_citta = c.cap_citta
);

--- QUERIES DI ANALISI ---

-- Quale è la distribuzione per genere dell'adesione percentuale ai concerti?

WITH percentuali_concerto AS (
    SELECT genere,
           nome AS concerto,
           (numero_biglietti_venduti::DECIMAL / numero_posti) * 100 AS percentuale_vendita
    FROM Concerto
    GROUP BY genere, nome, numero_biglietti_venduti, numero_posti
),
top_generi AS (
    SELECT genere
    FROM percentuali_concerto
    GROUP BY genere
    ORDER BY COUNT(*) DESC
    LIMIT 9
)

SELECT pc.genere,
       pc.concerto,
       pc.percentuale_vendita
FROM percentuali_concerto pc
JOIN top_generi tg
  ON pc.genere = tg.genere
ORDER BY pc.genere, pc.concerto;

-- Dato uno specifico artista, quale agenzia ha venduto più biglietti?

SELECT b.venditore AS agenzia,
       COUNT(*) AS biglietti_venduti
FROM Biglietto b
JOIN Ingaggio_Artista ia
  ON b.data_concerto = ia.data_concerto
 AND b.ora_concerto = ia.ora_concerto
 AND b.nome_ambiente = ia.nome_ambiente
 AND b.indirizzo_ambiente = ia.indirizzo_ambiente
 AND b.nome_citta = ia.nome_citta
 AND b.cap_citta = ia.cap_citta
JOIN Artista a
  ON ia.artista = a.nome_arte
WHERE a.nome_arte = 'Camden Stanton'
GROUP BY b.venditore
ORDER BY biglietti_venduti DESC;

-- Come sono distribuiti i concerti per città?

SELECT nome_citta,
       cap_citta,
       COUNT(*) AS numero_concerti
FROM Concerto
GROUP BY nome_citta, cap_citta
ORDER BY numero_concerti DESC;


-- Come sono distribuiti i biglietti per persona?

-- 1. Contiamo quanti biglietti ha comprato ogni persona
WITH biglietti_per_persona AS (
    SELECT proprietario,
           COUNT(*) AS num_biglietti
    FROM Biglietto
    GROUP BY proprietario
)
-- 2. Calcoliamo quante persone hanno comprato esattamente quel numero di biglietti
SELECT num_biglietti,
       COUNT(*) AS numero_persone
FROM biglietti_per_persona
GROUP BY num_biglietti
ORDER BY num_biglietti;
