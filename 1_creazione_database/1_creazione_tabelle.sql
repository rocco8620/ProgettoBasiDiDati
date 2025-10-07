-- TIPI DI DATO ----------
CREATE TYPE metodo_di_pagamento AS ENUM (
  'contanti',
  'carta_di_credito',
  'bitcoin'
);

-- TABELLE ----------
CREATE TABLE Persona (
	CF CHAR(16) PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	cognome VARCHAR(50) NOT NULL,
	email VARCHAR(50) UNIQUE NOT NULL,
	indirizzo VARCHAR(200) NOT NULL,
	metodo_pagamento metodo_di_pagamento NOT NULL
);

CREATE TABLE Agenzia (
	ragione_sociale VARCHAR(100) PRIMARY KEY
);

CREATE TABLE Genere (
	nome TEXT PRIMARY KEY
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
	numero_posti_massimo INTEGER NOT NULL CHECK(numero_posti_massimo > 0),
	PRIMARY KEY (nome, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (nome_citta, cap_citta) REFERENCES Citta(nome, cap) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Concerto (
	nome VARCHAR(200) NOT NULL, -- non fa parte della primary key perchè la chiave è già univoca
	numero_posti INTEGER NOT NULL CHECK (numero_posti > 0), -- un concerto ha almeno un posto disponibile
	numero_biglietti_venduti INTEGER NOT NULL CHECK (numero_biglietti_venduti >= 0 AND numero_biglietti_venduti <= numero_posti) DEFAULT 0,
	prezzo REAL NOT NULL CHECK (prezzo >= 0), -- un concerto potrebbe essere gratuito
	data DATE NOT NULL,
	ora TIME NOT NULL,	-- valutare check > data ordiera. Logico e funziona perchè viene controllato solo quando inserito o update. Il problema sta nel caricamento dei dati generati che hanno date del passato e quindi non passano. Potremmo dare un nome al constraint e disabilitarlo quando serve.
	-- ambiente
	nome_ambiente VARCHAR(50),
	indirizzo VARCHAR(200),
	-- città
	nome_citta VARCHAR(50),
	cap_citta CHAR(5),

	genere TEXT NOT NULL REFERENCES Genere (nome) ON UPDATE CASCADE ON DELETE RESTRICT,

	PRIMARY KEY (data, ora, nome_ambiente, indirizzo, nome_citta, cap_citta),
	FOREIGN KEY (
		nome_ambiente,
		indirizzo,
		nome_citta,
		cap_citta
	) REFERENCES Ambiente(
		nome,
		indirizzo,
		nome_citta,
		cap_citta
	) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Biglietto (
	id BIGSERIAL PRIMARY KEY, -- BIGSERIAL ha l'autoincrement di default
	venditore VARCHAR(100) NOT NULL REFERENCES Agenzia (ragione_sociale) ON UPDATE CASCADE ON DELETE RESTRICT,
	proprietario CHAR(16) NOT NULL REFERENCES Persona (CF) ON UPDATE CASCADE ON DELETE RESTRICT,

	data_vendita DATE NOT NULL DEFAULT CURRENT_DATE,	-- stesso discorso di data e ora del concerto
	ora_vendita TIME NOT NULL DEFAULT CURRENT_TIME,
	data_concerto DATE NOT NULL,
	ora_concerto TIME NOT NULL,
	nome_ambiente VARCHAR(50) NOT NULL,
	indirizzo_ambiente VARCHAR(200) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5) NOT NULL,

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

CREATE TABLE Artista_In_Gruppo (
	-- nonostante la relazione sia 0:N, se vengono specificati gli artisti per un gruppo, non possono esistere tuple con valori nulli
	artista VARCHAR(50) NOT NULL REFERENCES Artista(nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,
  gruppo VARCHAR(50) NOT NULL REFERENCES Gruppo(nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Ingaggio_Artista (
	-- concerto
	data_concerto DATE NOT NULL,
	ora_concerto TIME NOT NULL,
	nome_ambiente VARCHAR(50) NOT NULL,
	indirizzo_ambiente VARCHAR(200) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5) NOT NULL,

	artista VARCHAR(50) NOT NULL REFERENCES Artista (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

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
	nome_ambiente VARCHAR(50) NOT NULL,
	indirizzo_ambiente VARCHAR(200) NOT NULL,
	nome_citta VARCHAR(50) NOT NULL,
	cap_citta CHAR(5) NOT NULL,

	gruppo VARCHAR(50) NOT NULL REFERENCES Gruppo (nome_arte) ON UPDATE CASCADE ON DELETE RESTRICT,

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