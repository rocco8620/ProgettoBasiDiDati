# Install required packages if not already installed
# install.packages("RPostgres")
# install.packages("ggplot2")
# install.packages("DBI")
# install.packages("ggridges")

~~~r
library(DBI)
library(RPostgres)
library(ggplot2)
library(ggridges)


con <- dbConnect(
  RPostgres::Postgres(),
  dbname   = "progettobasididati",
  host     = "localhost",    # e.g. "localhost"
  port     = 5432,           # default PostgreSQL port
  user     = "postgres"
)

# QUERY 1
# Classifica generi con più concerti e distribuzione per gemere delle percentuali di adesione ai concerti
# Tipo grafico: RIDGES
# Valori fissati: NESSUNO

query <- "
WITH percentuali_concerto AS (
    SELECT genere,
           (numero_biglietti_venduti::DECIMAL / numero_posti) * 100 AS percentuale_vendita
    FROM Concerto
),
num_concerti_genere AS (
    SELECT genere,
           COUNT(*) AS num_concerti
    FROM Concerto
    GROUP BY genere
    ORDER BY num_concerti DESC
    LIMIT 10
)
SELECT pc.genere,
       ncg.num_concerti,
       pc.percentuale_vendita
FROM num_concerti_genere ncg
JOIN percentuali_concerto pc
  ON ncg.genere = pc.genere
ORDER BY ncg.num_concerti DESC, ncg.genere;
"

concert_data <- dbGetQuery(con, query)
concert_data$genere <- factor(
  concert_data$genere,
  levels = unique(concert_data$genere)
)  # Mantiene ordinamento dato da query

ggplot(concert_data, aes(y = genere, x = percentuale_vendita)) +
  geom_density_ridges(alpha=0.8, stat="binline", bins=20, fill="lightblue") +
  labs(
    title = "Distribuzione per genere delle percentuali di adesione ai concerti",
    x = "Percentuale di biglietti venduti",
    y = "Top 10 generi per numero di concerti (⟵ ascendente)"
  ) +
  theme_ridges() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_text(hjust = 0.5),
    axis.title.y = element_text(hjust = 0.5)
  )
ggsave("grafici/query 1.png", bg="white", width=10, height=6)

# QUERY 2
# Numero biglietti venduti dalle diverse agenzie per i concerti di un determinato artista
# Tipo grafico: BARPLOT
# Valori fissati: [Artista] Camden Stanton

query <- "
SELECT b.venditore AS agenzia,
       COUNT(*) AS biglietti_venduti
FROM Biglietto b
JOIN Ingaggio_Artista ia
  ON b.data_concerto = ia.data_concerto
 AND b.ora_concerto = ia.ora_concerto
 AND b.nome_ambiente = ia.nome_ambiente
 AND b.indirizzo_ambiente = ia.indirizzo_ambiente
 AND b.nome_citta = ia.nome_citta
 AND b.cap_citta = ia.cap_citta
WHERE ia.artista = 'Camden Stanton'
GROUP BY b.venditore
ORDER BY biglietti_venduti;
"

ticket_data <- dbGetQuery(con, query)
ticket_data$agenzia <- factor(
  ticket_data$agenzia,
  levels = ticket_data$agenzia
)  # Mantiene ordinamento dato da query

ggplot(ticket_data, aes(x = agenzia,
                        y = biglietti_venduti)) +
  geom_col(fill="lightblue", width=0.8, colour="black") +
  labs(
    title = "Num. biglietti venduti da agenzie per concerti dell'artista Camden Stanton (solista)",
    x = "Agenzia",
    y = "Biglietti venduti"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_text(hjust = 0.5),
    axis.title.y = element_text(hjust = 0.5)
  )
ggsave("grafici/query 2.png", bg="white", width=10, height=6)

# QUERY 3
# Classifica numero di concerti per città
# Tipo grafico: BARPLOT
# Valori fissati: NESSUNO

query <- "
SELECT nome_citta,
       cap_citta,
       COUNT(*) AS numero_concerti
FROM Concerto
GROUP BY nome_citta, cap_citta
ORDER BY numero_concerti;
"

concerti_data <- dbGetQuery(con, query)
concerti_data$nome_citta <- factor(
  paste(concerti_data$nome_citta, "- CAP", concerti_data$cap_citta),
  levels = paste(concerti_data$nome_citta, "- CAP", concerti_data$cap_citta)
)  # Mantiene ordinamento dato da query. Necessario concatenare cap a nome citta

ggplot(concerti_data, aes(x = nome_citta,
                          y = numero_concerti,
                          fill = nome_citta)) +
  geom_col(fill="lightblue", width=0.8, colour="black", show.legend = FALSE) +
  labs(title = "Numero di concerti per città",
       x = "Città",
       y = "Numero concerti") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_text(hjust = 0.5),
    axis.title.y = element_text(hjust = 0.5)
  )
ggsave("grafici/query 3.png", bg="white", width=10, height=6)

# QUERY 4
# Distribuzione numero biglietti acquistati per persona
# Tipo grafico: RIDGES
# Valori fissati: NESSUNO

query <- "
WITH biglietti_per_persona AS (
    SELECT proprietario,
           COUNT(*) AS num_biglietti
    FROM Biglietto
    GROUP BY proprietario
)
SELECT num_biglietti,
       COUNT(*) AS numero_persone
FROM biglietti_per_persona
GROUP BY num_biglietti
ORDER BY num_biglietti;
"

ticket_distribution <- dbGetQuery(con, query)

ggplot(ticket_distribution, aes(x = factor(num_biglietti), y = numero_persone)) +
  geom_col(fill="lightblue", width=1, colour="black") +
  labs(
    title = "Distribuzione biglietti per persona",
    x = "Numero di biglietti acquistati",
    y = "Numero di persone"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_text(hjust = 0.5),
    axis.title.y = element_text(hjust = 0.5)
  )
ggsave("grafici/query 4.png", bg="white", width=10, height=6)


dbDisconnect(con)