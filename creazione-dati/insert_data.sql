BEGIN;

SET CONSTRAINTS ALL DEFERRED;

COPY citta FROM '/tmp/citta.csv' DELIMITER ',' CSV HEADER;
COPY genere FROM '/tmp/genere.csv' DELIMITER ',' CSV HEADER;
COPY agenzia FROM '/tmp/agenzia.csv' DELIMITER ',' CSV HEADER;
COPY artista FROM '/tmp/artista.csv' DELIMITER ',' CSV HEADER;
COPY gruppo FROM '/tmp/gruppo.csv' DELIMITER ',' CSV HEADER;
COPY ambiente FROM '/tmp/ambiente.csv' DELIMITER ',' CSV HEADER;
--------
COPY persona FROM '/tmp/persona.csv' DELIMITER ',' CSV HEADER;
COPY diritto_prevendita FROM '/tmp/diritto_prevendita.csv' DELIMITER ',' CSV HEADER;
COPY artista_in_gruppo FROM '/tmp/artista_in_gruppo.csv' DELIMITER ',' CSV HEADER;
--------
COPY concerto FROM '/tmp/concerto.csv' DELIMITER ',' CSV HEADER; -- In questa riga tira error
COPY ingaggio_artista FROM '/tmp/ingaggio_artista.csv' DELIMITER ',' CSV HEADER;
COPY ingaggio_gruppo FROM '/tmp/ingaggio_gruppo.csv' DELIMITER ',' CSV HEADER;
COPY biglietto FROM '/tmp/biglietto.csv' DELIMITER ',' CSV HEADER;

COMMIT;

-- ROLLBACK;

--------

-- Pulisce tutte le tabelle del database
DO
$$
DECLARE
    tables TEXT;
BEGIN
    SELECT string_agg(format('%I.%I', schemaname, tablename), ', ') INTO tables
    FROM pg_tables
    WHERE schemaname = 'public'; -- change if your tables are in a different schema

    EXECUTE format('TRUNCATE TABLE %s CASCADE;', tables);
END;
$$;