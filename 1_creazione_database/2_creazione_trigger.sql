-- FUNZIONI GENERALI ----------

-- Controlla se un concerto ha almeno un ingaggio (artista e/o gruppo) collegato
-- PARAMS : attributi che compongono la chiave primaria di Concerto
-- RETURN : booleano se ha almeno un Ingaggio_*
CREATE OR REPLACE FUNCTION Check_Almeno_Un_Ingaggio_Concerto(
  conc_data DATE, conc_ora TIME, conc_nome_ambiente VARCHAR,
  conc_indirizzo VARCHAR, conc_nome_citta VARCHAR, conc_cap_citta CHAR
) RETURNS BOOLEAN LANGUAGE PLPGSQL AS
$$
  BEGIN
    RETURN (
      EXISTS (
        SELECT 1 FROM Ingaggio_Artista
        WHERE data_concerto = conc_data AND
              ora_concerto = conc_ora AND
              nome_ambiente = conc_nome_ambiente AND
              indirizzo_ambiente = conc_indirizzo AND
              nome_citta = conc_nome_citta AND
              cap_citta = conc_cap_citta
      ) OR EXISTS (
        SELECT 1 FROM Ingaggio_Gruppo
        WHERE data_concerto = conc_data AND
              ora_concerto = conc_ora AND
              nome_ambiente = conc_nome_ambiente AND
              indirizzo_ambiente = conc_indirizzo AND
              nome_citta = conc_nome_citta AND
              cap_citta = conc_cap_citta
      )
    );
  END;
$$;

-- Controlla se una persona ha almeno un biglietto registrato a suo nome
-- PARAMS : attributo chiave primaria di Persona
-- RETURN : booleano se ha almeno un Biglietto
CREATE OR REPLACE FUNCTION Check_Persona_Almeno_Un_Biglietto(pers CHAR)
  RETURNS BOOLEAN LANGUAGE PLPGSQL AS
$$
  BEGIN
    RETURN EXISTS (SELECT 1 FROM Biglietto WHERE proprietario = pers);
  END;
$$;

-- FUNZIONI PER TRIGGER ----------
-- Concerto deve avere almeno un ingaggio
CREATE OR REPLACE FUNCTION Check_Ingaggio_Concerto_trigger()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  DECLARE
    ok boolean;
  BEGIN
    IF NEW IS NULL THEN
      ok = Check_Almeno_Un_Ingaggio_Concerto(
        OLD.data_concerto, OLD.ora_concerto, OLD.nome_ambiente,
        OLD.indirizzo_ambiente, OLD.nome_citta, OLD.cap_citta
      );
    ELSE
      ok = Check_Almeno_Un_Ingaggio_Concerto(
        NEW.data, NEW.ora, NEW.nome_ambiente,
        NEW.indirizzo, NEW.nome_citta, NEW.cap_citta
      );
    END IF;

    IF NOT ok THEN
      RAISE EXCEPTION 'Concerto deve avere almeno un ingaggio';
      RETURN null;
    END IF;
    RETURN COALESCE(NEW, OLD);
  END;
$$;

-- Agenzia deve avere diritto di prevendita sul genere del concerto
CREATE OR REPLACE FUNCTION Check_Diritto_Prevendita_Agenzia_trigger()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  DECLARE
    genere_concerto TEXT;
  BEGIN
    -- Dal biglietto ricava il genere del concerto
    genere_concerto = (
      SELECT Concerto.genere
      FROM Concerto
      WHERE data = NEW.data_concerto AND
            ora = NEW.ora_concerto AND
            nome_ambiente = NEW.nome_ambiente AND
            indirizzo = NEW.indirizzo_ambiente AND
            nome_citta = NEW.nome_citta AND
            cap_citta = NEW.cap_citta
    );
    -- Controllo esistenza diritto di prevendita da parte dell'agenzia venditrice
    IF NOT EXISTS (
      SELECT 1 FROM Diritto_Prevendita
      WHERE agenzia = NEW.venditore AND
            genere = genere_concerto
    ) THEN
      RAISE EXCEPTION '% non ha diritto di prevendita per il genere %', NEW.venditore, genere_concerto;
      RETURN null;
    END IF;

    RETURN NEW;
  END;
$$;

-- Persona deve avere almeno un biglietto a lui intestato se non viene cancellata
CREATE OR REPLACE FUNCTION Check_Persona_Biglietto_trigger()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  DECLARE
    persona_esiste boolean;
    almeno_biglietto boolean;
  BEGIN
    -- almeno_biglietto    persona_esiste
    -- false               false              OK
    -- false               true              FAIL
    -- true                false              indefinito
    -- true                 true              OK

    persona_esiste = true;
    IF NEW IS NULL THEN
      persona_esiste = EXISTS (SELECT 1 FROM Persona WHERE CF = OLD.proprietario);
      almeno_biglietto = Check_Persona_Almeno_Un_Biglietto(OLD.proprietario);
    ELSE
      almeno_biglietto = Check_Persona_Almeno_Un_Biglietto(NEW.CF);
    END IF;

    IF persona_esiste AND NOT almeno_biglietto THEN
      RAISE EXCEPTION 'La persona deve avere almeno un biglietto';
    END IF;

    RETURN COALESCE(NEW, OLD);
  END;
$$;

-- Limite posti disponibili concerto < posti massimi ambiente
CREATE OR REPLACE FUNCTION Check_Limite_Posti_Disponibili()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  BEGIN
    IF NEW.numero_posti > (
      SELECT numero_posti_massimo
      FROM Ambiente
      WHERE nome = NEW.nome_ambiente AND
            indirizzo = NEW.indirizzo_ambiente AND
            nome_citta = NEW.nome_citta AND
            cap_citta = NEW.cap_citta
    ) THEN
        RAISE EXCEPTION 'Il numero di posti per il concerto deve essere minore al massimo per l''ambiente';
        RETURN null;
    END IF;
    RETURN NEW;
  END;
$$;

-- Gestione incremento/decremento attributo derivato numero biglietti venduti
CREATE OR REPLACE FUNCTION Numero_biglietti_venduti_Inc()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  BEGIN
    UPDATE Concerto
    SET numero_biglietti_venduti = numero_biglietti_venduti + 1
    WHERE data = NEW.data_concerto AND
          ora = NEW.ora_concerto AND
          nome_ambiente = NEW.nome_ambiente AND
          indirizzo = NEW.indirizzo_ambiente AND
          nome_citta = NEW.nome_citta AND
          cap_citta = NEW.cap_citta;
    RETURN NEW;
  END;
$$;

CREATE OR REPLACE FUNCTION Numero_biglietti_venduti_Dec()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
  BEGIN
    UPDATE Concerto
    SET numero_biglietti_venduti = numero_biglietti_venduti - 1
    WHERE data = OLD.data_concerto AND
          ora = OLD.ora_concerto AND
          nome_ambiente = OLD.nome_ambiente AND
          indirizzo = OLD.indirizzo_ambiente AND
          nome_citta = OLD.nome_citta AND
          cap_citta = OLD.cap_citta;
    RETURN OLD;
  END;
$$;

-- TRIGGER ----------
CREATE TRIGGER Agenzia_ha_Diritto_Prevendita
  BEFORE INSERT ON Biglietto
  FOR EACH ROW
  EXECUTE FUNCTION Check_Diritto_Prevendita_Agenzia_trigger();

CREATE CONSTRAINT TRIGGER Inserimento_Concerto
  AFTER INSERT ON Concerto
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION Check_Ingaggio_Concerto_trigger();

CREATE CONSTRAINT TRIGGER Cancellazione_Ingaggio_Artista
  AFTER DELETE ON Ingaggio_Artista
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION Check_Ingaggio_Concerto_trigger();

CREATE CONSTRAINT TRIGGER Cancellazione_Ingaggio_Gruppo
  AFTER DELETE ON Ingaggio_Gruppo
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION Check_Ingaggio_Concerto_trigger();

CREATE CONSTRAINT TRIGGER Persona_ha_Biglietto
  AFTER INSERT ON Persona
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION Check_Persona_Biglietto_trigger();

CREATE CONSTRAINT TRIGGER Ultimo_Biglietto_Persona
  AFTER DELETE ON Biglietto
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION Check_Persona_Biglietto_trigger();

-- Per attributo derivato: Concerto.numero_biglietti_venduti
CREATE TRIGGER Numero_biglietti_venduti_nuovo_Biglietto
  AFTER INSERT ON Biglietto
  FOR EACH ROW
  EXECUTE FUNCTION Numero_biglietti_venduti_Inc();

CREATE TRIGGER Numero_biglietti_venduti_canc_Biglietto
  AFTER DELETE ON Biglietto
  FOR EACH ROW
  EXECUTE FUNCTION Numero_biglietti_venduti_Dec();
  
CREATE TRIGGER Limite_Posti_Concerto_Ambiente
  BEFORE INSERT ON Concerto
  FOR EACH ROW
  EXECUTE FUNCTION Check_Limite_Posti_Disponibili();