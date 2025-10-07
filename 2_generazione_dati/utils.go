package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"reflect"
	"strconv"
	"time"
)

// Funzione per mantenere lo stesso formato in ogni tabella e convertire i diversi
// formati in stringhe
func formatValue(v reflect.Value) string {
	switch v.Kind() {
	case reflect.Int, reflect.Int64:
		return strconv.FormatInt(v.Int(), 10) // base 10
	case reflect.Float64:
		return strconv.FormatFloat(v.Float(), 'f', 2, 64) // float64 in stringa con 2 valori decimali
	case reflect.String:
		return v.String()
	case reflect.Struct:
		if v.Type() == reflect.TypeOf(time.Time{}) {
			return v.Interface().(time.Time).Format("2006-01-02") // formato della data
		}
	}
	return "" // serve per permettere alla funzione di ritornare una stringa, non sarà mai ""
}

// Scrive riga per riga i dati creati precedentemente in un file CSV
func saveToCSV(filename string, data any) {
	// crea la cartella per inserire all'interno i csv
	err := os.MkdirAll("./data", 0755)
	if err != nil {
		log.Fatalf("Errore nella creazione della cartella data: %v", err)
	}
	// crea il file
	file, err := os.Create(filename)
	if err != nil {
		log.Fatalf("Errore nella creazione del file %s: %v", filename, err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// controlla che il dato da inserire nel file è una "slice"
	v := reflect.ValueOf(data)
	if v.Kind() != reflect.Slice {
		log.Fatalf("I dati devono essere in formato slice, invece: %v", v.Kind())
	}
	// controlla che il dato non sia vuoto
	if v.Len() == 0 {
		log.Printf("Non c'è nessun dato da scriver per %s. Passo oltre.", filename)
		return
	}

	// scrive l'header del CSV
	firstElement := v.Index(0)
	t := firstElement.Type()
	var headers []string
	for i := range t.NumField() {
		// preleva il tag dalla struct in formato csv
		tag := t.Field(i).Tag.Get("csv")
		// se esiste, lo scrive in headers
		if tag != "" {
			headers = append(headers, tag)
		}
	}
	// scrive l'headers situato in headers all'interno del file e ferma
	// l'esecuzione in caso di errore
	if err := writer.Write(headers); err != nil {
		log.Fatalf("Errore scrivendo l'header nel CSV: %v", err)
	}

	// Scrive i dati creati in precedenza nel CSV
	for i := range v.Len() {
		rowElement := v.Index(i)
		var record []string
		for j := 0; j < rowElement.NumField(); j++ {
			fieldValue := rowElement.Field(j)
			record = append(record, formatValue(fieldValue)) // nel giusto formato
		}
		// scrive ogni riga della tabella situata in records all'interno del file
		// e ferma l'esecuzione in caso di errore
		if err := writer.Write(record); err != nil {
			log.Fatalf("Errore scrivendo i dati nel CSV: %v", err)
		}
	}

	log.Printf("Salvato con successo %s con %d records.", filename, v.Len())
}

// Crea due file: SQL e psql con tutte le istruzioni COPY necessarie.
func generateSQLFile() {
	// crea la cartella per inserire all'interno i csv
	err := os.MkdirAll("./data", 0755)
	if err != nil {
		log.Fatalf("Errore nella creazione della cartella data: %v", err)
	}
	// crea il file
	f1, err := os.Create("data/insert_data.sql")
	if err != nil {
		log.Fatal(err)
	}
	defer f1.Close()

	// crea il file
	f2, err := os.Create("data/insert_data-psql.sql")
	if err != nil {
		log.Fatal(err)
	}
	defer f2.Close()

	// psql: aggiunge prima dell'inserimento dei file usando psql un inizio di transazione assieme ai vincoli deferrable
	fmt.Fprintf(f2, "%s\n%s\n%s\n\n", "\\c progettobasididati", "BEGIN;", "SET CONSTRAINTS ALL DEFERRED;")

	// file da cui prelevare le informazioni da inserire nella base di dati
	files := []string{
		"citta.csv", "genere.csv", "agenzia.csv", "artista.csv", "gruppo.csv",
		"ambiente.csv", "persona.csv", "diritto_prevendita.csv", "artista_in_gruppo.csv",
		"concerto.csv", "ingaggio_artista.csv", "ingaggio_gruppo.csv", "biglietto.csv",
	}

	// per ogni file con le informazioni scrive il comando per la copia nei due formati
	for _, file := range files {
		table := file[:len(file)-4] // nome tabella = nome file senza ".csv"
		fmt.Fprintf(f1, "COPY %s FROM '%s' DELIMITER ',' CSV HEADER;\n", table, file)
		fmt.Fprintf(f2, "\\copy %s FROM '%s' WITH DELIMITER ',' CSV HEADER;\n", table, file)
	}

	// psql: incrementa l'indice dei biglietti non effettuato durante il \copy
	fmt.Fprintf(f2, "\n%s\n%s", "SELECT setval('biglietto_id_seq', (SELECT COUNT(*) FROM biglietto), true);", "COMMIT;")

	log.Println("Generazione dei file SQL insert_data.sql e insert_data-psql.sql finita senza errori")
}
