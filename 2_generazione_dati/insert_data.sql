-- Eseguire il codice GO per generare i file prima di eseguire questo script

COPY citta FROM 'citta.csv' DELIMITER ',' CSV HEADER;
COPY genere FROM 'genere.csv' DELIMITER ',' CSV HEADER;
COPY agenzia FROM 'agenzia.csv' DELIMITER ',' CSV HEADER;
COPY artista FROM 'artista.csv' DELIMITER ',' CSV HEADER;
COPY gruppo FROM 'gruppo.csv' DELIMITER ',' CSV HEADER;
COPY ambiente FROM 'ambiente.csv' DELIMITER ',' CSV HEADER;
COPY persona FROM 'persona.csv' DELIMITER ',' CSV HEADER;
COPY diritto_prevendita FROM 'diritto_prevendita.csv' DELIMITER ',' CSV HEADER;
COPY artista_in_gruppo FROM 'artista_in_gruppo.csv' DELIMITER ',' CSV HEADER;
COPY concerto FROM 'concerto.csv' DELIMITER ',' CSV HEADER;
COPY ingaggio_artista FROM 'ingaggio_artista.csv' DELIMITER ',' CSV HEADER;
COPY ingaggio_gruppo FROM 'ingaggio_gruppo.csv' DELIMITER ',' CSV HEADER;
COPY biglietto FROM 'biglietto.csv' DELIMITER ',' CSV HEADER;
