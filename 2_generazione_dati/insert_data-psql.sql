-- Eseguire il codice GO per generare i file prima di eseguire questo script

\c progettobasididati

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

\copy citta FROM 'citta.csv' WITH DELIMITER ',' CSV HEADER;
\copy genere FROM 'genere.csv' WITH DELIMITER ',' CSV HEADER;
\copy agenzia FROM 'agenzia.csv' WITH DELIMITER ',' CSV HEADER;
\copy artista FROM 'artista.csv' WITH DELIMITER ',' CSV HEADER;
\copy gruppo FROM 'gruppo.csv' WITH DELIMITER ',' CSV HEADER;
\copy ambiente FROM 'ambiente.csv' WITH DELIMITER ',' CSV HEADER;
\copy persona FROM 'persona.csv' WITH DELIMITER ',' CSV HEADER;
\copy diritto_prevendita FROM 'diritto_prevendita.csv' WITH DELIMITER ',' CSV HEADER;
\copy artista_in_gruppo FROM 'artista_in_gruppo.csv' WITH DELIMITER ',' CSV HEADER;
\copy concerto FROM 'concerto.csv' WITH DELIMITER ',' CSV HEADER;
\copy ingaggio_artista FROM 'ingaggio_artista.csv' WITH DELIMITER ',' CSV HEADER;
\copy ingaggio_gruppo FROM 'ingaggio_gruppo.csv' WITH DELIMITER ',' CSV HEADER;
\copy biglietto FROM 'biglietto.csv' WITH DELIMITER ',' CSV HEADER;

-- aggiorna il prossimo valore della sequenza biglietto.id, che non viene aggiornato utilizzando la copy
SELECT setval('biglietto_id_seq', (SELECT COUNT(*) FROM biglietto), true);
COMMIT;

