CREATE DATABASE ProgettoBasiDiDati;

-- TODO
--	- Vincolo per ciclo???
--	- DONE - Vincolo almeno un ingaggio per concerto --> altrimenti non può esistere
--	- DONE - Vincolo uno stesso artista/gruppo può partecipare al più ad un concerto nella stessa data
--	- CHECK - Vincolo diritto prevendita --> storico? Come mantengo l'informazione che in passato un agenzia aveva un diritto che oggi non ha più
--			A logica non dovrebbe mai capitare, comunque 		GUARDARE AVANTI
-- 	- fare trigger per edge cases (update di concerto) (anche relativo al ciclo) genere, ambiente
--	- DONE - Decidere gestione attributo derivato (numero posti venduti)
--	- REJECTED - Partizionamento della tabella Biglietto in base ad Agenzia
--

-- DOMANDE
--	- Ci sono tanti vincoli per la tabella Biglietto, si fanno tanti trigger o uno solo che li controlla tutti?
--


-- Funzioni
	-- per trigger - nome_arte
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

	-- per trigger - persona almeno un biglietto
CREATE OR REPLACE FUNCTION Delete_Zombie_Persona()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Biglietto WHERE proprietario = OLD.proprietario) THEN
		DELETE FROM Persona WHERE CF = OLD.proprietario;
	END IF;
	RETURN OLD;
END;
$$;

	-- per trigger - limite posti disponibili
CREATE OR REPLACE FUNCTION Check_Limite_Posti_Disponibili()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	IF 1 + (
	    SELECT numero_biglietti_venduti
	    FROM Concerto
	    WHERE data = NEW.data_concerto AND
		  ora = NEW.ora_concerto AND
		  nome_ambiente = NEW.nome_ambiente AND
		  indirizzo = NEW.indirizzo_ambiente AND
		  nome_citta = NEW.nome_citta AND
		  cap_citta = NEW.cap_citta
        ) > (
	    SELECT numero_posti_massimo
	    FROM Ambiente
	    WHERE nome = NEW.nome_ambiente AND
		  indirizzo = NEW.indirizzo_ambiente AND
		  nome_citta = NEW.nome_citta AND
		  cap_citta = NEW.cap_citta
	) THEN
		RAISE EXCEPTION 'Not available seats';
	END IF;
	RETURN NEW;
END;
$$;

	-- per trigger - l'agenzia ha il diritto di prevendita per vendere?
CREATE OR REPLACE FUNCTION Check_Diritto_Prevendita_Agenzia()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	IF NOT EXISTS (
	    SELECT Diritto_Prevendita.genere FROM Diritto_Prevendita
	    JOIN Concerto ON
		 data = NEW.data_concerto AND
		 ora = NEW.ora_concerto AND
		 nome_ambiente = NEW.nome_ambiente AND
		 indirizzo = NEW.indirizzo_ambiente AND
		 nome_citta = NEW.nome_citta AND
		 cap_citta = NEW.cap_citta
	    WHERE agenzia = NEW.venditore AND Concerto.genere = Diritto_Prevendita.genere
	) THEN
		RAISE EXCEPTION 'Agenzia has no pre-sale right';
	END IF;
	RETURN NEW;
END;
$$;

	-- per trigger - gestione attributo derivato biglietti venduti
CREATE OR REPLACE FUNCTION Numero_Biglietti_Venduti_Inc()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	UPDATE Concerto
	SET numero_biglietti_venduti = numero_biglietti_venduti + 1
	WHERE nome = NEW.nome_ambiente AND
	      indirizzo = NEW.indirizzo_ambiente AND
	      nome_citta = NEW.nome_citta AND
	      cap_citta = NEW.cap_citta;
	RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION Numero_Biglietti_Venduti_Dec()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	UPDATE Concerto
	SET numero_biglietti_venduti = numero_biglietti_venduti - 1
	WHERE nome = NEW.nome_ambiente AND
	      indirizzo = NEW.indirizzo_ambiente AND
	      nome_citta = NEW.nome_citta AND
	      cap_citta = NEW.cap_citta;
	RETURN OLD;
END;
$$;

	-- per trigger - un concerto deve avere almeno un ingaggio collegato
CREATE OR REPLACE FUNCTION Check_Ingaggio_Concerto()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	IF NOT EXISTS (
	    SELECT artista
	    FROM Ingaggio_Artista
	    WHERE data_concerto = NEW.data AND
		  ora_concerto = NEW.ora AND
		  nome_ambiente = NEW.nome_ambiente AND
		  indirizzo_ambiente = NEW.indirizzo AND
		  nome_citta = NEW.nome_citta AND
		  cap_citta = NEW.cap_citta
	) AND NOT EXISTS (
	    SELECT gruppo
	    FROM Ingaggio_Gruppo
	    WHERE data_concerto = NEW.data AND
		  ora_concerto = NEW.ora AND
		  nome_ambiente = NEW.nome_ambiente AND
		  indirizzo_ambiente = NEW.indirizzo AND
		  nome_citta = NEW.nome_citta AND
		  cap_citta = NEW.cap_citta
	) THEN
		RAISE EXCEPTION 'Concerto must have at least one Ingaggio_* ';
	END IF;
	RETURN NEW;
END;
$$;

-- Tipi di dato
CREATE TYPE metodo_di_pagamento AS ENUM (
	'contanti',
	'carta_di_credito',
	'bitcoin'
);


-- Tabelle
CREATE TABLE Persona (
	CF CHAR(16) PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	cognome VARCHAR(50) NOT NULL,
	email VARCHAR(50) UNIQUE NOT NULL,	-- candidato indice
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
	indirizzo VARCHAR(200),
	nome_citta VARCHAR(50),
	cap_citta CHAR(5),
	numero_posti_massimo INTEGER NOT NULL CHECK(numero_posti_massimo > 0),		-- condidato indice : es. tutti i concerti con almeno 100 posti
	PRIMARY KEY (nome, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (nome_citta, cap_citta) REFERENCES Citta(nome, cap) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Concerto (
	nome VARCHAR(200) NOT NULL, -- non fa parte della primary key perchè la chiave è già univoca		indice? forse poco utile
	numero_biglietti_venduti INTEGER NOT NULL,
	prezzo REAL NOT NULL CHECK(prezzo >= 0), -- un concerto potrebbe essere gratuito
	data DATE,
	ora TIME,
	-- ambiente
    nome_ambiente VARCHAR(50),
	indirizzo VARCHAR(200),
	-- città
	nome_citta VARCHAR(50),
	cap_citta CHAR(5),

	genere TEXT REFERENCES Genere (nome) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (data, ora, nome_ambiente, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (nome_ambiente, indirizzo, nome_citta, cap_citta) REFERENCES Ambiente(nome, indirizzo, nome_citta, cap_citta) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Biglietto (
	id BIGSERIAL PRIMARY KEY, -- BIGSERIAL ha l'autoincrement di default
	venditore VARCHAR(100) NOT NULL REFERENCES Agenzia (ragione_sociale) ON UPDATE CASCADE ON DELETE RESTRICT,
	proprietario CHAR(16) NOT NULL REFERENCES Persona (CF) ON UPDATE CASCADE ON DELETE RESTRICT,

	data_vendita TIMESTAMP NOT NULL,	-- indice?
	data_concerto DATE NOT NULL,
	ora_concerto TIME NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	FOREIGN KEY (
		data_concerto,
		ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data,
		ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Diritto_Prevendita (
	agenzia VARCHAR(100) REFERENCES Agenzia (ragione_sociale) ON UPDATE CASCADE ON DELETE RESTRICT,
	genere TEXT REFERENCES Genere (nome) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (agenzia, genere)
);

CREATE TABLE Artista (
	nome_arte VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Gruppo (
	nome_arte VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Ingaggio_Artista (
	-- concerto
	data_concerto DATE NOT NULL,
	ora_concerto TIME NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	artista VARCHAR(50) REFERENCES Artista (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

	UNIQUE (data_concerto, artista),

	PRIMARY KEY (data_concerto, ora_concerto, nome_ambiente, indirizzo_ambiente, nome_citta, cap_citta, artista),

	FOREIGN KEY (
		data_concerto,
		ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data,
		ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Ingaggio_Gruppo (
	-- concerto
	data_concerto DATE NOT NULL,
	ora_concerto TIME NOT NULL,
	nome_ambiente VARCHAR(200) NOT NULL,
	indirizzo_ambiente VARCHAR(50) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5),

	gruppo VARCHAR(50) REFERENCES Gruppo (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

	UNIQUE (data_concerto, gruppo),

	PRIMARY KEY (data_concerto, ora_concerto, nome_ambiente, indirizzo_ambiente, nome_citta, cap_citta, gruppo),

	FOREIGN KEY (
		data_concerto,
		ora_concerto,
		nome_ambiente,
		indirizzo_ambiente,
		nome_citta,
		cap_citta
	) REFERENCES Concerto(
		data,
		ora,
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	)	ON UPDATE CASCADE ON DELETE CASCADE
);


-- Trigger
	-- unicità del 'nome_arte'
CREATE TRIGGER Unique_Nome_Artista_Update
	BEFORE UPDATE ON Artista
	FOR EACH ROW
	WHEN (OLD.nome_arte IS DISTINCT FROM NEW.nome_arte)
	EXECUTE FUNCTION Check_Unique_Nome_Artista();

CREATE TRIGGER Unique_Nome_Artista_Insert
	BEFORE INSERT ON Artista
	FOR EACH ROW
	EXECUTE FUNCTION Check_Unique_Nome_Artista();

CREATE TRIGGER Unique_Nome_Gruppo_Update
	BEFORE UPDATE ON Artista
	FOR EACH ROW
	WHEN (OLD.nome_arte IS DISTINCT FROM NEW.nome_arte)
	EXECUTE FUNCTION Check_Unique_Nome_Gruppo();

CREATE TRIGGER Unique_Nome_Gruppo_Insert
	BEFORE INSERT ON Artista
	FOR EACH ROW
	EXECUTE FUNCTION Check_Unique_Nome_Gruppo();

	-- esistenza di sole persone con almeno un biglietto
	-- a livello di transazione è necessario impostare il constraint deferred
-- TODO : finire
CREATE TRIGGER Persona_ha_Biglietto
	AFTER INSERT ON Persona
	FOR EACH ROW
	EXECUTE FUNCTION Check_Persona_Biglietto();

CREATE TRIGGER Persona_Zombie
	AFTER DELETE ON Biglietto
	FOR EACH ROW
	EXECUTE FUNCTION Delete_Zombie_Persona();

	-- biglietti venduti < biglietti massimi ambiente
CREATE TRIGGER Limite_Biglietti
	BEFORE INSERT ON Biglietto
	FOR EACH ROW
	EXECUTE FUNCTION Check_Limite_Posti_Disponibili();

	-- l'agenzia ha diritto di prevendita per vendere il biglietto?
CREATE TRIGGER Agenzia_ha_Diritto_Prevendita
	BEFORE INSERT ON Biglietto
	FOR EACH ROW
	EXECUTE FUNCTION Check_Diritto_Prevendita_Agenzia();

	-- gestione attributo derivato (biglietti venduti)
CREATE TRIGGER Nuovo_Biglietto
	AFTER INSERT ON Biglietto
	FOR EACH ROW
	EXECUTE FUNCTION Numero_Biglietti_Venduti_Inc();

CREATE TRIGGER Cancellazione_Biglietto
	AFTER DELETE ON Biglietto
	FOR EACH ROW
	EXECUTE FUNCTION Numero_Biglietti_Venduti_Dec();

CREATE TRIGGER Ingaggio_Concerto
	BEFORE INSERT ON Concerto
	FOR EACH ROW
	EXECUTE FUNCTION Check_Ingaggio_Concerto();
