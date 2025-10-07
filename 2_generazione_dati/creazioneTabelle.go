package main

import (
	"fmt"
	"log"
	"math"
	"math/rand"
	"time"

	"github.com/brianvoe/gofakeit/v7"
)

// Creazione dati per la tabella Citta
func creazioneCitta() []Citta {

	// variabili locali per il salvataggio dei dati
	citta := make([]Citta, 0, NUM_CITTA)
	uniqueCittaCAP := make(map[string]struct{})

	for len(citta) < NUM_CITTA {
		nome := gofakeit.City()
		cap := gofakeit.Zip()[:5]

		// crea il dato finale da inserire nel CSV
		key := nome + cap

		// controlla se key casualmente è già stato creato
		if _, ok := uniqueCittaCAP[key]; !ok {
			// aggiunge l'accoppiata "città + cap" alla variabile temporanea citta
			// e alla lista dei cap unici creati
			citta = append(citta, Citta{Nome: nome, Cap: cap})
			uniqueCittaCAP[key] = struct{}{}
		}
	}
	log.Printf("Generato %d record per Citta.", len(citta))

	return citta
}

// Creazione dati per la tabella Genere
func creazioneGeneri() []Genere {

	// variabili locali per il salvataggio dei dati
	generi := make([]Genere, 0, NUM_GENERI)

	// shuffledGeneri := make([]string, len(GENERI_MUSICALI))
	// copy(shuffledGeneri, GENERI_MUSICALI)
	// rand.Shuffle(len(shuffledGeneri), func(i, j int) {
	// 	shuffledGeneri[i], shuffledGeneri[j] = shuffledGeneri[j], shuffledGeneri[i]
	// })

	for i := range NUM_GENERI {
		// formatta il genere nella struct per facilitarne l'uso nelle altre funzioni
		generi = append(generi, Genere{Nome: GENERI_MUSICALI[i]})
	}
	log.Printf("Generato %d record per Genere.", len(generi))

	return generi
}

// Creazione dati per la tabella Agenzia
func creazioneAgenzie() []Agenzia {

	// variabili locali per il salvataggio dei dati
	agenzie := make([]Agenzia, 0, NUM_AGENZIE)
	uniqueRagioneSociale := make(map[string]struct{})

	for len(agenzie) < NUM_AGENZIE {
		// crea il dato finale da inserire nel CSV
		rs := gofakeit.Company() + " SpA"

		// controlla se rs casualmente è già stato creato
		if _, ok := uniqueRagioneSociale[rs]; !ok {
			// aggiunge il nome della Azienda alla variabile temporanea agenzie
			// e alla lista delle ragioni sociali uniche create
			agenzie = append(agenzie, Agenzia{RagioneSociale: rs})
			uniqueRagioneSociale[rs] = struct{}{}
		}
	}
	log.Printf("Generato %d record per Agenzia.", len(agenzie))

	return agenzie
}

// Creazione dati per le tabella Artista e Gruppo
func creazioneArtisti() ([]Artista, []Gruppo) {

	// variabili locali per il salvataggio dei dati
	allNomeArtePool := make([]string, 0, NUM_ARTISTI+NUM_GRUPPI)
	uniqueNomeArte := make(map[string]struct{})

	for len(allNomeArtePool) < NUM_ARTISTI+NUM_GRUPPI {
		// crea il dato finale da inserire nel CSV
		name := gofakeit.FirstName() + " " + gofakeit.LastName()

		// controlla se il nome casualmente è già stato creato
		if _, ok := uniqueNomeArte[name]; !ok {
			// aggiunge il nome creato alla varaibile temporanea per la creazione
			// di Artisti e Gruppo, viene aggiunto anche alla lista dei nomi unici creati
			allNomeArtePool = append(allNomeArtePool, name)
			uniqueNomeArte[name] = struct{}{}
		}
	}

	// rand.Shuffle(len(allNomeArtePool), func(i, j int) {
	// 	allNomeArtePool[i], allNomeArtePool[j] = allNomeArtePool[j], allNomeArtePool[i]
	// })

	artisti := make([]Artista, NUM_ARTISTI)
	for i := range NUM_ARTISTI {
		// aggiunge il nome creato alla varaibile temporanea artisti
		artisti[i] = Artista{NomeArte: allNomeArtePool[i]}
	}
	log.Printf("Generato %d record per Artista.", len(artisti))

	gruppi := make([]Gruppo, NUM_GRUPPI)
	for i := range NUM_GRUPPI {
		// aggiunge il nome creato alla varaibile temporanea gruppi
		// viene incrementata i per prelevare altri nomi e non riutilizzare solo quelli dell'artista
		gruppi[i] = Gruppo{NomeArte: allNomeArtePool[NUM_ARTISTI+i]}

	}
	log.Printf("Generato %d record per Gruppo.", len(gruppi))

	return artisti, gruppi
}

// Creazione dati per la tabella Ambiente
func creazioneAmbiente(citta []Citta, r *rand.Rand) []Ambiente {

	// variabili locali per il salvataggio dei dati
	ambienti := make([]Ambiente, 0, NUM_AMBIENTI)
	uniqueAmbientePK := make(map[string]struct{})

	for len(ambienti) < NUM_AMBIENTI {
		// creazione dell'ambiente usando la città creata in precedenza e aggiungendo
		// "Arena" ad una parola casuale per il nome del luogo.
		cittaRef := citta[r.Intn(len(citta))]
		nome := gofakeit.Word() + " Arena"
		// creazione dell'indirizzo del luogo dell'ambiente
		indirizzo := gofakeit.Address().Address

		// crea il dato finale da inserire nel CSV
		key := nome + indirizzo + cittaRef.Nome + cittaRef.Cap

		// controlla se key casualmente è già stato creato
		if _, ok := uniqueAmbientePK[key]; !ok {
			// aggiunge il nome creato alla varaibile temporanea ambienti e viene
			// aggiunto anche alla lista degli ambienti unici creati
			ambienti = append(ambienti, Ambiente{
				Nome: nome, Indirizzo: indirizzo, NomeCitta: cittaRef.Nome, CapCitta: cittaRef.Cap,
				NumeroPostiMassimo: r.Intn(4901) + 100, // posti disponibili vanno da 100 a 5000
			})
			uniqueAmbientePK[key] = struct{}{}
		}
	}
	log.Printf("Generato %d record per Ambiente.", len(ambienti))

	return ambienti
}

// Creazione dati per la tabella Persona
func creazionePersona(r *rand.Rand) []Persona {

	// variabili locali per il salvataggio dei dati
	persone := make([]Persona, 0, NUM_PERSONE)
	uniqueCF := make(map[string]struct{})
	uniqueEmail := make(map[string]struct{})

	for len(persone) < NUM_PERSONE {

		// creazione dei dati fittizzi usati per differenziare le persone
		// regular expression per creare un codice fiscale italiano
		cf := gofakeit.Regex("[A-Z]{6}[0-9]{2}[A-Z]{1}[0-9]{2}[A-Z]{1}[0-9]{3}[A-Z]{1}")
		email := gofakeit.Email()

		// controlla se i dati appena creati sono unici
		if _, ok := uniqueCF[cf]; !ok {
			if _, ok := uniqueEmail[email]; !ok {
				// aggiunge la persona appena creata alla varaibile temporanea persone e
				// vengono aggiunti alle liste per controllare se i nuovi sono unici
				persone = append(persone, Persona{
					CF:              cf,
					Nome:            gofakeit.FirstName(),
					Cognome:         gofakeit.LastName(),
					Email:           email,
					Indirizzo:       gofakeit.Address().Address,
					MetodoPagamento: METODO_PAGAMENTO_ENUM[r.Intn(len(METODO_PAGAMENTO_ENUM))], // prende un pagamento casuale dalla lista
				})
				uniqueCF[cf] = struct{}{}
				uniqueEmail[email] = struct{}{}
			}
		}
	}
	log.Printf("Generato %d record per Persona.", len(persone))

	return persone
}

// Creazione dati per la tabella DirittoPrevendita
func creazioneDirittoPrevendita(agenzie []Agenzia, generi []Genere, r *rand.Rand) []DirittoPrevendita {

	// variabili locali per il salvataggio dei dati
	dirittoPrevendita := make([]DirittoPrevendita, 0)
	uniqueAgenziaGenere := make(map[string]struct{})

	for _, agenziaRow := range agenzie {

		// genera una lista di generi casuali per permettere ad ogni azienda di
		// avere le prevendite casuali anzichè sempre le stesse

		// copia generi
		shuffledGeneri := make([]string, len(generi))
		for i, g := range generi {
			shuffledGeneri[i] = g.Nome
		}

		// rende casuale l'ordine dei generi
		rand.Shuffle(len(shuffledGeneri), func(i, j int) {
			shuffledGeneri[i], shuffledGeneri[j] = shuffledGeneri[j], shuffledGeneri[i]
		})

		numRights := r.Intn(NUM_DIRITTI_PREVENDITA_PER_AGENZIA) + 1
		for i := range numRights {
			if i >= len(shuffledGeneri) {
				break
			}

			// crea il dato da inserire nel CSV
			genereNome := shuffledGeneri[i]
			key := agenziaRow.RagioneSociale + genereNome

			// controlla se i dati appena creati sono unici
			if _, ok := uniqueAgenziaGenere[key]; !ok {
				// aggiunge la prevendita appena creata alla varaibile temporanea e
				// alla lista per controllare se le nuove prevendita sono uniche
				dirittoPrevendita = append(dirittoPrevendita, DirittoPrevendita{
					Agenzia: agenziaRow.RagioneSociale, Genere: genereNome,
				})
				uniqueAgenziaGenere[key] = struct{}{}
			}
		}
	}
	log.Printf("Generato %d record per Diritto_Prevendita.", len(dirittoPrevendita))

	return dirittoPrevendita
}

// Creazione dati per la tabella ArtistaInGruppo
func creazioneArtistaInGruppo(artisti []Artista, gruppi []Gruppo, r *rand.Rand) []ArtistaInGruppo {

	// variabili locali per il salvataggio dei dati
	artistaInGruppo := make([]ArtistaInGruppo, 0, NUM_ARTISTI_IN_GRUPPI)
	uniqueArtistaGruppo := make(map[string]struct{})

	// limite superiore per non permettere un ciclo infinito con solamente
	// creazione di coppie artista-gruppo già create in precedenza
	attempts := 0
	maxAttempts := NUM_ARTISTI_IN_GRUPPI * 5

	// finché esistono artisti che possono far parte di di un gruppo
	for len(artistaInGruppo) < NUM_ARTISTI_IN_GRUPPI && attempts < maxAttempts {
		attempts++

		// finito gli artisti o i gruppi da cui prelevare i dati
		if len(artisti) == 0 || len(gruppi) == 0 {
			break
		}

		// viene prelevato casualmente uun nome artista e un nome gruppo
		artistaRef := artisti[r.Intn(len(artisti))].NomeArte
		gruppoRef := gruppi[r.Intn(len(gruppi))].NomeArte

		// crea il dato finale da inserire nel CSV
		key := artistaRef + gruppoRef

		// controlla se casualmente è già stato creato
		if _, ok := uniqueArtistaGruppo[key]; !ok {
			// aggiunge l'artista nel gruppo alla varaibile temporanea artistaInGruppo e
			// anche alla lista artisti in un gruppo unici creati.
			// in questo modo si limita un artista a far aprte al più ad un singolo gruppo
			artistaInGruppo = append(artistaInGruppo, ArtistaInGruppo{Artista: artistaRef, Gruppo: gruppoRef})
			uniqueArtistaGruppo[key] = struct{}{}
		}
	}
	log.Printf("Generato %d record per ArtistaInGruppo.", len(artistaInGruppo))

	return artistaInGruppo
}

// Creazione dati per la tabella Concerto
func creazioneConcerto(ambienti []Ambiente, r *rand.Rand, generi []Genere) []Concerto {

	// variabili locali per il salvataggio dei dati
	concerti := make([]Concerto, 0, NUM_CONCERTI)
	uniqueConcertoPK := make(map[string]struct{})

	// Genera concerti solamente negli ultimi 10 anni
	startDate := time.Now().AddDate(-10, 0, 0)
	endDate := time.Now()

	for len(concerti) < NUM_CONCERTI {

		// viene prelevato casualmente un ambiente e un genere
		ambienteRef := ambienti[r.Intn(len(ambienti))]
		genereRef := generi[r.Intn(len(generi))]
		// crea ulteriori dati casuali
		dataConcerto := gofakeit.DateRange(startDate, endDate)
		oraConcerto := fmt.Sprintf("%02d:%02d:00", r.Intn(6)+18, r.Intn(2)*30)
		nomeConcerto := gofakeit.HackerPhrase() + " Live"
		// crea il prezzo casualmente da 0 a 150, ma per avere anche concerti gtatuiti
		// se il prezzo generato e compreso tra 0 e 5 viene posto a 0
		x := gofakeit.Float64Range(0, 150.0)
		var prezzo float64
		if x < 5 {
			prezzo = 0
		} else {
			prezzo = x
		}
		// genera il numero di posti massimo in modo casuale con un range da 50 a capienza posti massima
		numeroPosti := r.Intn(ambienteRef.NumeroPostiMassimo-50) + 50

		// crea il dato da inserire nel CSV
		pk := fmt.Sprintf("%v|%v|%v|%v|%v|%v", dataConcerto.Format("2006-01-02"), oraConcerto, ambienteRef.Nome, ambienteRef.Indirizzo, ambienteRef.NomeCitta, ambienteRef.CapCitta)

		// controlla se i dati appena creati sono unici
		if _, ok := uniqueConcertoPK[pk]; !ok {
			// aggiunge il concerto appena creato alla varaibile temporanea e
			// alla lista per controllare se i nuovi concerti sono unici
			concerti = append(concerti, Concerto{
				Nome: nomeConcerto, NumeroPosti: numeroPosti, NumeroBigliettiVenduti: 0, Prezzo: prezzo, Data: dataConcerto, Ora: oraConcerto,
				NomeAmbiente: ambienteRef.Nome, IndirizzoAmbiente: ambienteRef.Indirizzo, NomeCitta: ambienteRef.NomeCitta, CapCitta: ambienteRef.CapCitta,
				Genere: genereRef.Nome,
			})
			uniqueConcertoPK[pk] = struct{}{}
		}
	}
	log.Printf("Generato %d record per Concerto.", len(concerti))
	return concerti
}

// Creazione dati per le tabelle IngaggioArtista e IngaggioGruppo
func creazioneIngaggio(concerti []Concerto, r *rand.Rand, artisti []Artista, gruppi []Gruppo) ([]IngaggioArtista, []IngaggioGruppo) {

	// variabili locali per il salvataggio dei dati
	ingaggioArtista := make([]IngaggioArtista, 0)
	ingaggioGruppo := make([]IngaggioGruppo, 0)
	uniqueIngaggioArtistaPK := make(map[string]struct{})
	uniqueIngaggioGruppoPK := make(map[string]struct{})

	// garantire un ingaggio per ogni concerto
	for _, concerto := range concerti {

		// numero di ingaggi per il corrente concerto
		num_ingaggi_concerto := r.Intn(MAX_INGAGGI_CONCERTO) + 1

		for range num_ingaggi_concerto {
			// sceglie in modo casuale se il concerto è di un artista o di un gruppo
			isArtist := r.Float64() < 0.5
	
			if isArtist && len(artisti) > 0 { // artista
				// do-while per garantire che venga trovato un'artista valido per l'inaggaggio
				for {
					// preleva un artista in modo casuale da quelli creati precedentemente
					artistaRef := artisti[r.Intn(len(artisti))].NomeArte
					// crea il dato da inserire nel CSV
					key := fmt.Sprintf("%v|%v", concerto.Data.Format("2006-01-02"), artistaRef)
					// controlla se i dati appena creati sono unici
					if _, ok := uniqueIngaggioArtistaPK[key]; !ok {
						// aggiunge l'ingaggio appena creato alla varaibile temporanea e
						// alla lista per controllare se quelli nuovi sono unici
						ingaggioArtista = append(ingaggioArtista, IngaggioArtista{
							DataConcerto: concerto.Data, OraConcerto: concerto.Ora, NomeAmbiente: concerto.NomeAmbiente,
							IndirizzoAmbiente: concerto.IndirizzoAmbiente, NomeCitta: concerto.NomeCitta, CapCitta: concerto.CapCitta, Artista: artistaRef,
						})
						uniqueIngaggioArtistaPK[key] = struct{}{}
						break;
					}
				}
			} else if len(gruppi) > 0 { // gruppo
				// do-while per garantire che venga trovato un gruppo valido per l'inaggaggio
				for {
					// preleva un gruppo in modo ocasuale da quelli creati precedentemente
					gruppoRef := gruppi[r.Intn(len(gruppi))].NomeArte
					// crea il dato da inserire nel CSV
					key := fmt.Sprintf("%v|%v", concerto.Data.Format("2006-01-02"), gruppoRef)
					// controlla se i dati appena creati sono unici
					if _, ok := uniqueIngaggioGruppoPK[key]; !ok {
						// aggiunge l'ingaggio appena creato alla varaibile temporanea e
						// alla lista per controllare se quelli nuovi sono unici
						ingaggioGruppo = append(ingaggioGruppo, IngaggioGruppo{
							DataConcerto: concerto.Data, OraConcerto: concerto.Ora, NomeAmbiente: concerto.NomeAmbiente,
							IndirizzoAmbiente: concerto.IndirizzoAmbiente, NomeCitta: concerto.NomeCitta, CapCitta: concerto.CapCitta, Gruppo: gruppoRef,
						})
						uniqueIngaggioGruppoPK[key] = struct{}{}
						break;
					}
				}
			}
		}

	}

	log.Printf("Generato %d record per Ingaggio_Artista.", len(ingaggioArtista))
	log.Printf("Generato %d record per Ingaggio_Gruppo.", len(ingaggioGruppo))

	return ingaggioArtista, ingaggioGruppo
}

// Creazione dati per la tabella Biglietto
func creazioneBiglietto(persone []Persona, r *rand.Rand, concerti []Concerto, dirittoPrevendita []DirittoPrevendita) []Biglietto {

	// variabili locali per il salvataggio dei dati
	biglietti := make([]Biglietto, 0, MAX_BIGLIETTI)
	concertoBigliettiVenduti := make(map[string]int)

	bigliettoIDCounter := 1
	totalBiglietti := 0

	for i, personaRow := range persone {

		// controlla se è stato raggiunto il numero di biglietti prefissato
		if totalBiglietti >= MAX_BIGLIETTI {
			panic("Troppi biglietti generati, raggiunto limite")
		}

		// numero random generato con distribuzione normale (media 2, std 4.6) tra 1 e MAX_BIGLIETTI_PER_PERSONA.
		numBiglietti := int(math.Abs(float64(int(r.NormFloat64() * 4.6 + 2) % MAX_BIGLIETTI_PER_PERSONA)) + 1)

		attempts := 0
		maxAttempts := numBiglietti * 10 // per evitare loop infinito
		ticketsCreated := 0

		for ticketsCreated < numBiglietti && attempts < maxAttempts {
			attempts++

			// preleva in modo casuale il concerto creato prima e il suo genere
			concertoRef := concerti[r.Intn(len(concerti))]
			concertoGenere := concertoRef.Genere

			var validAgenzie []string
			for _, dp := range dirittoPrevendita {
				// aggiunge le agenzie con diritto di prevendita dello stesso genere del concerto
				if dp.Genere == concertoGenere {
					validAgenzie = append(validAgenzie, dp.Agenzia)
				}
			}

			// controllo di aver preso almeno una azienda con diritto di prevendita per il concerto
			if len(validAgenzie) == 0 {
				continue // salta al prossimo ciclo
			}

			// preleva casualmente un'agenzia da quele con diritto di prevendita
			venditoreAgenzia := validAgenzie[r.Intn(len(validAgenzie))]
			// crea la data e ora di vendita, la data è generata in modo casuale partendo da 6 mesi prima della data del concerto stesso
			dataVendita := gofakeit.DateRange(concertoRef.Data.AddDate(0, -6, 0), concertoRef.Data)
			oraVendita := fmt.Sprintf("%02d:%02d:%02d", r.Intn(24), r.Intn(60), r.Intn(60))

			// crea il dato da inserire nel CSV
			pk := fmt.Sprintf("%v|%v|%v|%v|%v|%v",
				concertoRef.Data.Format("2006-01-02"), concertoRef.Ora, concertoRef.NomeAmbiente,
				concertoRef.IndirizzoAmbiente, concertoRef.NomeCitta, concertoRef.CapCitta)

			// controlla sia possibile la creazione del biglietto se ci sono ancora posti disponibili nell'ambiente
			if concertoBigliettiVenduti[pk] < concertoRef.NumeroPosti {
				// aggiunge il biglietto appena creato alla varaibile temporanea e
				// alla lista per controllare se quelli nuovi sono unici
				biglietti = append(biglietti, Biglietto{
					ID: bigliettoIDCounter, Venditore: venditoreAgenzia, Proprietario: personaRow.CF, DataVendita: dataVendita,
					OraVendita: oraVendita, DataConcerto: concertoRef.Data, OraConcerto: concertoRef.Ora, 
					NomeAmbiente: concertoRef.NomeAmbiente,	IndirizzoAmbiente: concertoRef.IndirizzoAmbiente, 
					NomeCitta: concertoRef.NomeCitta, CapCitta: concertoRef.CapCitta,
				})
				// incrementa ogni contatore ausiliario
				bigliettoIDCounter++
				concertoBigliettiVenduti[pk]++
				ticketsCreated++
				totalBiglietti++
			}
		}

		// la persona senza biglietto non può esistere
		if ticketsCreated == 0 {
			// eliminazione persona
			persone = append(persone[:i], persone[i+1:]...)

		}
	}

	log.Printf("Generati %d record per Biglietto.", len(biglietti))

	return biglietti
}
