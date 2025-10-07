package main

import (
	"fmt"
	"math/rand"
	"path/filepath"
	"time"

	"github.com/brianvoe/gofakeit/v7"
)

// Parametri generazione dati
const (
	NUM_CITTA                          	= 20
	NUM_GENERI                         	= 15
	NUM_AGENZIE                        	= 15
	NUM_ARTISTI                        	= 120
	NUM_GRUPPI                         	= 30
	NUM_AMBIENTI                       	= 30
	NUM_DIRITTI_PREVENDITA_PER_AGENZIA 	= 6
	NUM_ARTISTI_IN_GRUPPI              	= 70
	NUM_CONCERTI						= 3100
	MAX_INGAGGI_CONCERTO				= 4
	MAX_BIGLIETTI                      	= 1345025
	MAX_BIGLIETTI_PER_PERSONA          	= 15
	NUM_PERSONE                        	= 290000
)

func main() {
	gofakeit.Seed(0)                                     // set del seed per avere sempre la creazione degli stessi dati
	r := rand.New(rand.NewSource(time.Now().UnixNano())) // creazione di un seed per le estrazioni casuali dai dati creati

	fmt.Println("Generazione dati in corso...")

	// Citta
	citta := creazioneCitta()
	// Genere
	generi := creazioneGeneri()
	// Agenzia
	agenzie := creazioneAgenzie()
	// Artista e Gruppo
	artisti, gruppi := creazioneArtisti()
	// Ambiente
	ambienti := creazioneAmbiente(citta, r)
	// Persona
	persone := creazionePersona(r)
	// DirittoPrevendita
	dirittoPrevendita := creazioneDirittoPrevendita(agenzie, generi, r)
	// ArtistaInGruppo
	artistaInGruppo := creazioneArtistaInGruppo(artisti, gruppi, r)
	// Concerto
	concerti := creazioneConcerto(ambienti, r, generi)
	// IngaggioArtista e IngaggioGruppo
	ingaggioArtista, ingaggioGruppo := creazioneIngaggio(concerti, r, artisti, gruppi)
	// Biglietto
	biglietti := creazioneBiglietto(persone, r, concerti, dirittoPrevendita)

	fmt.Println("\nSalvataggio dei dati in file CSV e creazione file SQL")

	// CSV
	saveToCSV(filepath.Join("data", "citta.csv"), citta)
	saveToCSV(filepath.Join("data", "genere.csv"), generi)
	saveToCSV(filepath.Join("data", "agenzia.csv"), agenzie)
	saveToCSV(filepath.Join("data", "artista.csv"), artisti)
	saveToCSV(filepath.Join("data", "gruppo.csv"), gruppi)
	saveToCSV(filepath.Join("data", "ambiente.csv"), ambienti)
	saveToCSV(filepath.Join("data", "persona.csv"), persone)
	saveToCSV(filepath.Join("data", "diritto_prevendita.csv"), dirittoPrevendita)
	saveToCSV(filepath.Join("data", "artista_in_gruppo.csv"), artistaInGruppo)
	saveToCSV(filepath.Join("data", "concerto.csv"), concerti)
	saveToCSV(filepath.Join("data", "ingaggio_artista.csv"), ingaggioArtista)
	saveToCSV(filepath.Join("data", "ingaggio_gruppo.csv"), ingaggioGruppo)
	saveToCSV(filepath.Join("data", "biglietto.csv"), biglietti)

	// SQL
	generateSQLFile()

	fmt.Println("\nGenerazione, salvataggio dei dati e creazione del file SQL completati!")
}
