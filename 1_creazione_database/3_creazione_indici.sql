-- BIGLIETTO
CREATE INDEX biglietto_venditore_idx ON Biglietto (venditore);
CREATE INDEX biglietto_proprietario_idx ON Biglietto USING HASH (proprietario);

-- DIRITTO_PREVENDITA
CREATE INDEX diritto_prevendita_agenzia_idx ON Diritto_Prevendita (agenzia);

-- CONCERTO
CREATE INDEX concerto_prezzo_idx ON Concerto (prezzo);
CREATE INDEX concerto_data_idx ON Concerto (data);