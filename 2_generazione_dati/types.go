package main

import "time"

// Metodo di pagamento
var METODO_PAGAMENTO_ENUM = []string{"contanti", "carta_di_credito", "bitcoin"}

// Lista generi musicali
var GENERI_MUSICALI = []string{
	"Rock", "Pop", "Jazz", "Blues", "Classica", "Hip Hop", "Elettronica",
	"Metal", "Reggae", "Country", "Folk", "R&B", "Indie", "Punk", "Techno",
}

// Strutture Dati tabelle
type Citta struct {
	Nome string `csv:"nome"`
	Cap  string `csv:"cap"`
}

type Genere struct {
	Nome string `csv:"nome"`
}

type Agenzia struct {
	RagioneSociale string `csv:"ragione_sociale"`
}

type Artista struct {
	NomeArte string `csv:"nome_arte"`
}

type Gruppo struct {
	NomeArte string `csv:"nome_arte"`
}

type Ambiente struct {
	Nome               string `csv:"nome"`
	Indirizzo          string `csv:"indirizzo"`
	NomeCitta          string `csv:"nome_citta"`
	CapCitta           string `csv:"cap_citta"`
	NumeroPostiMassimo int    `csv:"numero_posti_massimo"`
}

type Persona struct {
	CF              string `csv:"CF"`
	Nome            string `csv:"nome"`
	Cognome         string `csv:"cognome"`
	Email           string `csv:"email"`
	Indirizzo       string `csv:"indirizzo"`
	MetodoPagamento string `csv:"metodo_pagamento"`
}

type DirittoPrevendita struct {
	Agenzia string `csv:"agenzia"`
	Genere  string `csv:"genere"`
}

type ArtistaInGruppo struct {
	Artista string `csv:"artista"`
	Gruppo  string `csv:"gruppo"`
}

type Concerto struct {
	Nome                   string    `csv:"nome"`
	NumeroPosti            int       `csv:"numero_posti"`
	NumeroBigliettiVenduti int       `csv:"numero_biglietti_venduti"`
	Prezzo                 float64   `csv:"prezzo"`
	Data                   time.Time `csv:"data"`
	Ora                    string    `csv:"ora"`
	NomeAmbiente           string    `csv:"nome_ambiente"`
	IndirizzoAmbiente      string    `csv:"indirizzo"`
	NomeCitta              string    `csv:"nome_citta"`
	CapCitta               string    `csv:"cap_citta"`
	Genere                 string    `csv:"genere"`
}

type IngaggioArtista struct {
	DataConcerto      time.Time `csv:"data_concerto"`
	OraConcerto       string    `csv:"ora_concerto"`
	NomeAmbiente      string    `csv:"nome_ambiente"`
	IndirizzoAmbiente string    `csv:"indirizzo_ambiente"`
	NomeCitta         string    `csv:"nome_citta"`
	CapCitta          string    `csv:"cap_citta"`
	Artista           string    `csv:"artista"`
}

type IngaggioGruppo struct {
	DataConcerto      time.Time `csv:"data_concerto"`
	OraConcerto       string    `csv:"ora_concerto"`
	NomeAmbiente      string    `csv:"nome_ambiente"`
	IndirizzoAmbiente string    `csv:"indirizzo_ambiente"`
	NomeCitta         string    `csv:"nome_citta"`
	CapCitta          string    `csv:"cap_citta"`
	Gruppo            string    `csv:"gruppo"`
}

type Biglietto struct {
	ID                int       `csv:"id"`
	Venditore         string    `csv:"venditore"`
	Proprietario      string    `csv:"proprietario"`
	DataVendita       time.Time `csv:"data_vendita"`
	OraVendita        string	`csv:"ora_vendita"`
	DataConcerto      time.Time `csv:"data_concerto"`
	OraConcerto       string    `csv:"ora_concerto"`
	NomeAmbiente      string    `csv:"nome_ambiente"`
	IndirizzoAmbiente string    `csv:"indirizzo_ambiente"`
	NomeCitta         string    `csv:"nome_citta"`
	CapCitta          string    `csv:"cap_citta"`
}
