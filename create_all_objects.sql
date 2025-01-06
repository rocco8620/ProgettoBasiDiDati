CREATE DATABASE ProgettoBasiDiDati;

CREATE TYPE metodo_di_pagamento AS ENUM (
		'contanti',
		'carta_di_credito',
		'bitcoin'
);

CREATE TABLE Persona (
    -- TODO: Aggiungere un TRIGGER che elimini una persona una volta che non ci sono più biglietti a suo nome
	CF CHAR(16) PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	cognome VARCHAR(50) NOT NULL,
	email VARCHAR(50) UNIQUE NOT NULL,
	indirizzo VARCHAR(200) NOT NULL,
	metodo_pagamento metodo_di_pagamento NOT NULL
);


CREATE TABLE Genere (
	nome TEXT PRIMARY KEY
);

CREATE TABLE Agenzia (
	ragione_sociale VARCHAR(100) PRIMARY KEY
);

CREATE TABLE Citta (
	nome VARCHAR(50),
	cap CHAR(5) NOT NULL CHECK (cap ~ '[0-9]{5}'),
	PRIMARY KEY (nome, cap)
);


CREATE TABLE Ambiente (
	nome VARCHAR(50),
	indirizzo VARCHAR(50),
	nome_citta VARCHAR(50),
	cap_citta CHAR(5),
	numero_posti_massimo INTEGER NOT NULL CHECK(numero_posti_massimo > 0),
	PRIMARY KEY (nome, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (nome_citta, cap_citta) REFERENCES Citta(nome, cap) ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE Concerto (
    -- TODO: Aggiungere un TRIGGER che verifichi che non venga creato un biglietto se i posti sono finiti in quell'ambiente/concerto
	nome VARCHAR(200) NOT NULL, -- non fa parte della primary key perchè la chiave è già univoca
	numero_biglietti_venduti INTEGER NOT NULL,
	prezzo REAL NOT NULL CHECK(prezzo >= 0), -- un concerto potrebbe essere gratuito
	data_ora TIMESTAMP,
	-- ambiente
	indirizzo VARCHAR(50),
	nome_ambiente VARCHAR(200),
	-- città
	nome_citta VARCHAR(50),
	cap_citta CHAR(5),

	PRIMARY KEY (data_ora, nome_ambiente, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (nome_ambiente, indirizzo) REFERENCES Ambiente(nome, indirizzo) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (nome_citta, cap_citta) REFERENCES Citta(nome, CAP) ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE Biglietto (
	id BIGSERIAL PRIMARY KEY, -- BIGSERIAL ha l'autoincrement di default
	venditore VARCHAR(100) NOT NULL REFERENCES Agenzia (ragione_sociale) ON UPDATE CASCADE ON DELETE RESTRICT,
	proprietario CHAR(16) NOT NULL REFERENCES Persona (CF) ON UPDATE CASCADE ON DELETE RESTRICT,

	data_vendita TIMESTAMP NOT NULL,
	data_ora_concerto TIMESTAMP NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	FOREIGN KEY (
		data_ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data_ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE RESTRICT
);




CREATE TABLE Diritto_Prevendita (
	ragione_sociale VARCHAR(100) REFERENCES Agenzia (ragione_sociale) ON UPDATE CASCADE ON DELETE RESTRICT,
	genere TEXT REFERENCES Genere (nome) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (ragione_sociale, genere)
);



CREATE TABLE Artista (
	nome_arte VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Gruppo (
	nome_arte VARCHAR(50) PRIMARY KEY
);


CREATE OR REPLACE FUNCTION Check_Unique_Nome_Artista()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Gruppo WHERE nome_arte = NEW.nome_arte) THEN
        RAISE EXCEPTION 'Duplicated nome_arte: %', NEW.nome_arte;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER Unique_Nome_Artista_Update
    BEFORE UPDATE ON Artista
    FOR EACH ROW
    WHEN (OLD.nome_arte IS DISTINCT FROM NEW.nome_arte)
    EXECUTE FUNCTION Check_Unique_Nome_Artista();

CREATE TRIGGER Unique_Nome_Artista_Insert
    BEFORE INSERT ON Artista
    FOR EACH ROW
    EXECUTE FUNCTION Check_Unique_Nome_Artista();


CREATE OR REPLACE FUNCTION Check_Unique_Nome_Gruppo()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Artista WHERE nome_arte = NEW.nome_arte) THEN
        RAISE EXCEPTION 'Duplicated nome_arte: %', NEW.nome_arte;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER Unique_Nome_Gruppo_Update
    BEFORE UPDATE ON Artista
    FOR EACH ROW
    WHEN (OLD.nome_arte IS DISTINCT FROM NEW.nome_arte)
    EXECUTE FUNCTION Check_Unique_Nome_Gruppo();

CREATE TRIGGER Unique_Nome_Gruppo_Insert
    BEFORE INSERT ON Artista
    FOR EACH ROW
    EXECUTE FUNCTION Check_Unique_Nome_Gruppo();

CREATE TABLE Ingaggio_Artista (
  -- concerto
  data_vendita TIMESTAMP NOT NULL,
	data_ora_concerto TIMESTAMP NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	artista VARCHAR(50) REFERENCES Artista (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (data_vendita, data_ora_concerto, nome_ambiente, indirizzo_ambiente, nome_citta, cap_citta, artista),

	FOREIGN KEY (
		data_ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data_ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Ingaggio_Gruppo (
  -- concerto
  data_vendita TIMESTAMP NOT NULL,
	data_ora_concerto TIMESTAMP NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	gruppo VARCHAR(50) REFERENCES Gruppo (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (data_vendita, data_ora_concerto, nome_ambiente, indirizzo_ambiente, nome_citta, cap_citta, gruppo),

	FOREIGN KEY (
		data_ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data_ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE CASCADE
);