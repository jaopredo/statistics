#import "@preview/ctheorems:1.1.3": *
#import "@preview/lovelace:0.3.0": *
#show: thmrules.with(qed-symbol: $square$)

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages, stroke: 1pt + luma(100))

#import "@preview/tablex:0.0.9": tablex, rowspanx, colspanx, cellx

#set page(width: 21cm, height: 30cm, margin: 1.5cm)

#set par(
  justify: true
)

#set figure(supplement: "Figura")

#set heading(numbering: "1.1.1")

#let theorem = thmbox("theorem", "Teorema")
#let corollary = thmplain(
  "corollary",
  "Corolário",
  base: "theorem",
  titlefmt: strong
)
#let definition = thmbox("definition", "Definição", inset: (x: 1.2em, top: 1em))
#let example = thmplain("example", "Exemplo").with(numbering: none)
#let proof = thmproof("proof", "Demonstração")

#set math.equation(
  numbering: "(1)",
  supplement: none,
)
#show ref: it => {
  // provide custom reference for equations
  if it.element != none and it.element.func() == math.equation {
    // optional: wrap inside link, so whole label is linked
    link(it.target)[(#it)]
  } else {
    it
  }
}

#show table.cell.where(y: 0): it => {
  set text(fill: white, weight: "bold")
  show math.equation: set text(fill: white)
  it
}

#set table(
  fill: (x, y) => if y == 0 {
    rgb("#333333") // Dark gray header
  } else if calc.even(y) {
    rgb("#f9f9f9") // Light gray alternating rows
  } else {
    none
  },
  stroke: (x, y) => (
    top: if y == 0 { 1.5pt + rgb("#333333") } else { none },
    bottom: if y == 0 { 1.2pt + rgb("#333333") } else { 0.5pt + rgb("#e0e0e0") },
    left: none,
    right: none,
  )
)

#set text(
  font: "Arial",
  size: 11pt,
)

#show heading: it => {
  if it.level == 1 {
    [
      #block(
        width: 100%,
        height: 1cm,
        text(
          size: 1em,
          weight: "bold",
          it.body
        )
      )
    ]
  } else {
    it
  }
}


// ============================ PRIMEIRA PÁGINA =============================
#align(center + top)[
  FGV EMAp

  João Pedro Jerônimo
]

#align(horizon + center)[
  #text(17pt)[
    Dados faltantes e estimação por máxima verossimilhança
  ]
]

#align(bottom + center)[
  Rio de Janeiro

  2026
]

#pagebreak()

= Introdução

A presença de dados faltantes é um desafio comum em análises estatísticas aplicadas, frequentemente decorrente de falhas em sensores, perdas de transmissão ou indisponibilidade operacional. A abordagem mais intuitiva — porém metodologicamente ineficiente — consiste na análise de casos completos (Complete Case Analysis, ou CC), que descarta sumariamente qualquer linha com observações parciais. Essa prática não apenas desperdiça informações valiosas sobre as variáveis observadas, mas também introduz viés sistemático quando o mecanismo de perda não é puramente aleatório.

Em contrapartida, técnicas fundamentadas na teoria da máxima verossimilhança permitem contornar essas limitações de forma matematicamente rigorosa. Uma contribuição notável de T. W. Anderson (1957) demonstra que, sob a suposição de normalidade bivariada e um padrão de dados faltantes do tipo _Missing at Random_ (MAR, ou perda ao acaso), a log-verossimilhança dos dados observados pode ser fatorada de forma elegante. Essa fatoração decompõe o problema conjunto em subproblemas independentes (uma média univariada e uma regressão linear), permitindo obter os estimadores de máxima verossimilhança de forma direta, sem a necessidade de algoritmos numéricos iterativos.

Neste relatório, investiguei esse problema utilizando o conjunto de dados reais `airquality` do R, que contém $n = 153$ medições diárias de parâmetros de qualidade do ar em Nova York, coletadas entre maio e setembro de 1973. Foquei minha análise em duas variáveis principais: a radiação solar ($Y_1$, medida em Langleys) e a concentração de ozônio ($Y_2$, medida em partes por bilhão, ppb). Apresento a análise exploratória, a avaliação do viés da estimativa por casos completos, a aplicação do estimador de máxima verossimilhança de Anderson, a quantificação de incerteza por bootstrap paramétrico e não paramétrico, e um estudo de simulação sobre a eficiência relativa desses estimadores. As demonstrações matemáticas formais encontram-se detalhadas no @apendice:provas.

= Análise Exploratória
O primeiro passo da análise consiste na classificação de cada uma das 153 observações em padrões de dados faltantes com base na presença de $Y_1$ (radiação solar) e $Y_2$ (ozônio). Essa classificação resulta nos seguintes quantitativos:
- *Casos Completos*: $111$ observações, nas quais ambas as variáveis são registradas;
- *Casos Parciais ($Y_1$ observado, $Y_2$ ausente)*: $35$ observações;
- *Casos Invertidos ($Y_2$ observado, $Y_1$ ausente)*: $5$ observações;
- *Casos Completamente Ausentes*: $2$ observações, nas quais ambas as variáveis são faltantes.

Para o meu par de variáveis, o padrão é aproximadamente monotônico se eu desconsiderar as 5 observações com padrão invertido e os 2 casos totalmente ausentes. Como a grande maioria das observações com dados incompletos pertence ao padrão parcial (35 observações de ozônio faltantes quando a radiação está disponível, contra apenas 5 casos com radiação faltante e ozônio disponível), posso tratar a estrutura de dados como *aproximadamente monotônica*, sendo $Y_1$ a variável mais completa (disponível em 146 dias) e $Y_2$ a mais incompleta (disponível em 116 dias).

A suposição de normalidade bivariada é crucial para a aplicação direta das fórmulas de Anderson. Para avaliar visualmente a linearidade e a distribuição conjunta das variáveis, analisei o gráfico de dispersão de $Y_2$ contra $Y_1$ para as observações completas, testando também transformações logarítmicas. Os gráficos de dispersão resultantes estão apresentados na @fig:dispersao.

#figure(
  image("../images/different_transformations.png", width: 80%),
  caption: [Gráficos de dispersão entre $Y_1$ (Solar.R) e $Y_2$ (Ozone) sob diferentes escalas e transformações.]
) <fig:dispersao>

Visualmente, a escala original ($Y_1$ vs $Y_2$) apresenta uma clara relação não linear e uma forte heterocedasticidade: a variabilidade dos níveis de ozônio é pequena para níveis baixos de radiação solar, mas se dispersa amplamente à medida que a radiação solar aumenta. A transformação logarítmica em $Y_2$, isto é, o gráfico de $Y_1$ vs $ln(Y_2)$, lineariza a tendência média e estabiliza a variabilidade em toda a faixa de valores observados de radiação.

Para aprofundar essa avaliação, construí estimativas não paramétricas de densidade conjunta por meio de diagramas de nível (curvas de contorno de densidade kernel bivariada), ilustrados na @fig:contornos. 

#figure(
  image("../images/curvas_de_nivel.png", width: 80%),
  caption: [Curvas de contorno de densidade conjunta estimada (Kernel KDE) para as variáveis na escala original e sob transformações logarítmicas.]
) <fig:contornos>

Os contornos para a escala original mostram-se achatados contra o eixo horizontal e esticados verticalmente para valores altos de radiação, indicando fuga da normalidade. Já a escala com $Y_2$ transformado em $ln(Y_2)$ exibe contornos elípticos bem definidos e concêntricos, o que é uma forte evidência visual a favor da distribuição normal bivariada. 

Para confirmar formalmente essa hipótese, realizei testes de normalidade multivariada (Mardia, Henze-Zirkler e Royston) para as quatro transformações possíveis, cujas hipóteses são:
$ H_0: "Os dados provêm de uma distribuição normal multivariada" \
H_1: "Os dados não provêm de uma distribuição normal multivariada" $

Os p-valores obtidos revelaram que todos os testes rejeitam formalmente a hipótese nula de normalidade conjunta a um nível de significância de 5% (todos com $p < 0.001$ nos testes HZ e Royston, e assimetria de Mardia). No entanto, o teste de curtose de Mardia não conseguiu rejeitar a hipótese nula para os dados originais ($p = 0.567$) e para a transformação com $Y_2$ logarítmico ($p = 0.611$). Diante das evidências visuais robustas de simetria elíptica, linearidade e estabilização de variância, a escala com $Y_2$ transformado logaritmicamente — isto é, a análise conjunta de $Y_1 = "Solar.R"$ e $Y_2^* = ln("Ozone")$ — é selecionada como a mais adequada e será adotada para o restante deste relatório.

Para ilustrar o impacto prático de descartar dados incompletos, comparei as estimativas da média amostral da radiação solar ($Y_1$) sob duas condições: (i) utilizando apenas os $r = 111$ casos completos; (ii) utilizando todos os $n = 146$ casos em que $Y_1$ foi observado. Os resultados estão resumidos na @tab:media_y1.

#align(center)[
  #figure(
    table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, left, left, left, left),
      [*Grupo*], [*Observações*], [*Média*], [*Desvio Padrão*], [*Erro Padrão*],
      [Casos Completos ($r$)], [111], [184.8018], [91.1523], [8.6518],
      [Todos Observados ($n$)], [146], [185.9315], [90.0584], [7.4533]
    ),
    supplement: [Tabela]
  )<tab:media_y1>
]

As duas estimativas diferem numericamente, com a média baseada em todos os casos disponíveis ($185.9315$) ligeiramente superior à de casos completos ($184.8018$). O aspecto crítico reside na precisão da estimativa: o erro padrão da média é substancialmente menor quando uso todos os casos disponíveis ($7.4533$ contra $8.6518$). 

Esse comportamento é matematicamente dedutível, uma vez que a variância da média amostral de uma variável sob amostragem aleatória simples é dada por $"Var"(overline(Y)_1) = sigma_(11) / N$, o que resulta em um erro padrão proporcional a $1 / sqrt(N)$. Como os desvios padrões amostrais dos dois grupos são quase idênticos ($91.15$ vs $90.06$), o maior tamanho amostral do grupo completo ($146$ em comparação com $111$) expande o denominador da fração, reduzindo o erro padrão. Esse resultado exemplifica de forma clara o desperdício de eficiência que a eliminação de dados faltantes parciais acarreta.

Por fim, a modelagem de dados faltantes requer a adoção de pressupostos sobre o mecanismo gerador da ausência. O mecanismo Missing at Random (MAR) pressupõe que a probabilidade de um dado estar ausente pode depender das variáveis observadas, mas não dos valores ausentes em si. No meu contexto, assumir que a probabilidade de $Y_2$ (ozônio) estar ausente depende apenas do valor observado de $Y_1$ (radiação solar) significa que a chance de falha no monitoramento do ozônio em um determinado dia pode estar relacionada à quantidade de radiação solar registrada naquele dia, mas, condicionado a essa radiação, ela não depende de qual seria a real concentração de ozônio. 

Essa suposição é meteorológica e operacionalmente plausível. Níveis baixos de radiação solar indicam dias muito nublados, chuvosos ou com tempestades severas. Tais condições climáticas adversas estão diretamente associadas a maior incidência de quedas de energia elétrica, falhas de comunicação de dados ou danos físicos a sensores expostos, inviabilizando a operação da estação de monitoramento de Roosevelt Island. Em contrapartida, dias ensolarados (alta radiação) têm operação estável. Como a radiação capta esse estado climático, ela atua como um preditor suficiente para a probabilidade de perda, validando o pressuposto MAR.

= O Estimador de Casos Completos e Avaliação de Viés

Considerando o par de variáveis normalizado $(Y_1, ln(Y_2))$, estimei inicialmente os cinco parâmetros da distribuição normal bivariada utilizando exclusivamente os $r = 111$ casos completos. Utilizando as fórmulas de máxima verossimilhança convencionais (com divisão pelo tamanho do subconjunto $r$), as estimativas amostrais são:
- Médias: $hat(mu)_1^"CC" = 184.8018$ e $hat(mu)_2^"CC" = 3.4159$
- Variâncias: $hat(sigma)_(11)^"CC" = 8233.8887$ e $hat(sigma)_(22)^"CC" = 0.74297$ (desvios padrões correspondentes de $90.7408$ e $0.8620$, respectivamente)
- Covariância: $hat(sigma)_(12)^"CC" = 35.6744$.

Em relação ao erro padrão da média de $Y_1$, observei anteriormente que a estimativa com o conjunto total ($n = 146$) é mais precisa que a de casos completos ($r = 111$). A razão teórica de ganho de precisão decorrente puramente do tamanho de amostra é dada por:
$ "Razão Teórica" = sqrt(frac(r, n)) = sqrt(frac(111, 146)) approx 0.8719 $

Calculando a razão observada entre os erros padrões empíricos estimados nos dados reais, obtenho:
$ "Razão Observada" = frac("EP"_("todos"), "EP"_("completo")) = frac(7.4533, 8.6518) approx 0.8615 $

A proximidade entre a razão observada ($0.8615$) e a razão teórica ($0.8719$) confirma numericamente a perda de eficiência. A leve divergência ocorre unicamente porque os desvios padrões amostrais diferem minimamente entre as duas frações de dados devido à flutuação amostral.

Sob o mecanismo MAR, o estimador de casos completos para a média da segunda variável, $hat(mu)_2^"CC"$, torna-se viesado. Intuitivamente, isso ocorre devido a um viés de seleção: como a probabilidade de observabilidade de $Y_2$ depende diretamente de $Y_1$, restringir a amostra apenas aos dias em que ambos estão disponíveis seleciona de forma desproporcional dias com maior radiação solar. Uma vez que as duas variáveis apresentam uma correlação positiva clara, selecionar dias com alta radiação solar seleciona também dias com maiores concentrações de ozônio. Portanto, a média de ozônio calculada apenas nos casos completos superestima sistematicamente a verdadeira média populacional $mu_2$.

Para quantificar e comprovar esse viés empiricamente, realizei uma simulação de Monte Carlo com $1.000$ réplicas amostrais de tamanho $N = 153$ geradas a partir da distribuição normal bivariada com parâmetros verdadeiros iguais às estimativas de casos completos calculadas anteriormente. Em cada réplica, apliquei artificialmente o mecanismo de dados faltantes MAR, no qual a probabilidade de perda de $Y_2$ aumenta à medida que $Y_1$ diminui, seguindo uma curva logística:
$ P("ausência"_i mid y_(i, 1)) = "logit"^(-1)(-1.15 - 1.5 z_i), quad z_i = frac(y_(i, 1) - mu_1, sqrt(sigma_(11))) $

Para cada amostra simulada sob MAR, apliquei o estimador de casos completos para $mu_2$. A distribuição das estimativas simuladas é mostrada na @fig:vies.

#figure(
  image("../images/simulacao_vies_estimadores.png", width: 55%),
  caption: [Distribuição empírica do estimador de casos completos $hat(mu)_2^"CC"$ em 1.000 simulações sob mecanismo MAR, demonstrando o viés positivo em relação ao valor verdadeiro.]
) <fig:vies>

Os resultados consolidados da simulação mostram:
- Média Verdadeira de $mu_2$ na simulação: $3.4159$
- Média das estimativas simuladas de $hat(mu)_2^"CC"$: $3.5434$
- Viés estimado médio: $+0.1275$
- Erro padrão da média simulada: $0.0789$.

Um teste t para uma amostra para a hipótese nula de viés nulo ($H_0: "viés" = 0$) resultou em uma estatística de teste $t = 51.107$, com um p-valor virtualmente igual a zero ($p approx 5.3 times 10^(-281)$). Esse resultado confirma de forma inequívoca que o estimador de casos completos é estatisticamente viesado para a direita sob um mecanismo de dados faltantes ao acaso (MAR).

Finalmente, construí o intervalo de confiança analítico de 95% para $mu_2$ usando o estimador de casos completos, baseado na distribuição t de Student com $r - 1 = 110$ graus de liberdade:
$ "IC"_(95%) (mu_2^"CC") = hat(mu)_2^"CC" plus.minus t_(0.975, 110) times frac(s_2, sqrt(r)) = 3.4159 plus.minus 1.9818 times 0.08218 = [3.2531, 3.5788] $

Embora esse intervalo tenha uma largura de $0.3257$, o fato de o estimador pontual ser sistematicamente viesado invalida a cobertura nominal do intervalo. Em termos práticos, sob MAR, o intervalo de confiança construído a partir de casos completos é deslocado para cima e falha em conter o verdadeiro parâmetro populacional com a frequência desejada de 95%.

= Estimação por Máxima Verossimilhança (Anderson)

Para contornar o viés sistemático do estimador de casos completos e resgatar a eficiência dos dados parciais, recorri à modelagem por máxima verossimilhança baseada na fatoração proposta por T. W. Anderson (1957). Essa abordagem aproveita que a probabilidade de perda de $Y_2$ obedece ao mecanismo MAR para fatorar a verossimilhança observada em duas componentes independentes: uma dependente apenas de $Y_1$ (que usa todos os $n = 146$ casos de radiação solar) e outra referente à distribuição condicional de $Y_2$ dado $Y_1$ (que usa os $r = 111$ casos completos). A derivação matemática formal desta fatoração e dos respectivos estimadores está detalhada no @apendice:provas.

A partir desse procedimento, o estimador de máxima verossimilhança (MV) para a média da variável incompleta $mu_2$ assume a seguinte forma analítica:
$ hat(mu)_2^"MV" = overline(y)_2 + hat(beta)_(21 dot 1) (hat(mu)_1^"MV" - overline(x)_1) $

onde $overline(x)_1$ e $overline(y)_2$ são as médias amostrais de $Y_1$ e $Y_2$ estimadas nos $r = 111$ casos completos, $hat(mu)_1^"MV" = 185.9315$ é a média global de $Y_1$ obtida usando todas as $n = 146$ observações disponíveis, e $hat(beta)_(21 dot 1) = s_(12)/s_(11)$ é o coeficiente de regressão linear de $Y_2$ contra $Y_1$ estimado a partir do subconjunto de casos completos.

A implementação desse estimador e das respectivas fórmulas de variâncias/covariâncias nos dados reais de qualidade do ar resultou nos parâmetros bivariados finais detalhados na @tab:comparacao, onde também é apresentada a comparação com o estimador simples de casos completos (CC).

#align(center)[
  #figure(
    table(
      columns: (auto, auto, auto, auto),
      align: (left, right, right, right),
      [*Parâmetro*], [*Estimador CC*], [*Estimador Anderson*], [*Diferença Absoluta*],
      [$mu_1$ (Média de Solar.R)], [184.80180], [185.93151], [1.12971],
      [$mu_2$ (Média de $ln("Ozone")$)], [3.41593], [3.42082], [0.00489],
      [$sigma_(11)$ (Var de Solar.R)], [8233.88865], [8054.96791], [178.92074],
      [$sigma_(22)$ (Var de $ln("Ozone")$)], [0.74297], [0.73961], [0.00336],
      [$sigma_(12)$ (Covariância)], [35.67441], [34.89921], [0.77520]
    ),
    supplement: [Tabela]
  )<tab:comparacao>
]

A comparação revela alterações consistentes em todos os parâmetros estimados da distribuição conjunta. As diferenças observadas ocorrem porque o estimador de Anderson incorpora a informação contida nas 35 observações parciais (onde apenas a radiação solar está disponível).

Para compreender fisicamente e estatisticamente a correção aplicada à média de ozônio ($mu_2$), decomponho a diferença entre os estimadores MV e CC:
$ hat(mu)_2^"MV" - hat(mu)_2^"CC" = 3.42082 - 3.41593 = 0.00489 $

Pela equação do estimador de Anderson, essa diferença é exatamente igual ao termo de correção:
$ "Correção" = hat(beta)_(21 dot 1) (hat(mu)_1^"MV" - overline(x)_1) = 0.00433 times (185.93151 - 184.80180) = 0.00489 $

A direção e a magnitude dessa correção fazem perfeito sentido meteorológico:
1. O termo $(hat(mu)_1^"MV" - overline(x)_1) = 1.12971$ indica que as observações com dados completos apresentam, em média, um nível de radiação solar inferior à média global observada ($184.80$ vs $185.93$). Ou seja, a amostra de casos completos sub-representa a radiação solar do período.
2. O coeficiente de regressão linear condicional é positivo ($hat(beta)_(21 dot 1) = 0.00433$), refletindo que maior radiação solar está associada a maiores concentrações de ozônio (já que a radiação catalisa as reações fotoquímicas de formação de ozônio troposférico).
3. Como os casos completos sub-representam a radiação solar média, a média simples de ozônio calculada apenas nesses dias ($overline(y)_2 = 3.41593$) subestima a média populacional sob o mecanismo MAR. O estimador de Anderson corrige essa distorção aplicando o ajuste positivo de $+0.00489$, elevando a estimativa consistente de máxima verossimilhança para $3.42082$.

= Análise de Incerteza

Como o estimador de Anderson é uma função não linear de estatísticas calculadas em dois subconjuntos distintos de dados, a obtenção de fórmulas analíticas fechadas para o seu erro padrão é complexa. Diante disso, implementei procedimentos de bootstrap paramétrico e não paramétrico (com $B = 2.000$ réplicas) para quantificar com precisão sua incerteza. 

No bootstrap paramétrico, simulei novas amostras a partir do modelo bivariado estimado $cal(N)_2(hat(mu)^"MV", hat(Sigma)^"MV")$, impondo nelas o mesmo padrão de dados faltantes observado nos dados reais e recalculando o estimador de Anderson. No bootstrap não paramétrico, realizei a reamostragem das linhas com reposição. Os intervalos de confiança de 95% resultantes para a média de ozônio $mu_2$ estão apresentados na @tab:bootstrap.

#align(center)[
  #figure(
    table(
      columns: (auto, auto, auto, auto, auto, auto),
      inset: 10pt,
      align: (horizon, horizon, horizon, horizon, horizon, horizon),
      [*Método*], [*Média*], [*Erro Padrão*], [*IC Inferior (2.5%)*], [*IC Superior (97.5%)*], [*Largura do IC*],
      [CC (Analítico t-Student)], [3.41593], [0.08218], [3.25306], [3.57880], [0.32574],
      [Anderson (Boot. Paramétrico)], [3.42082], [0.08083], [3.25950], [3.57726], [0.31775],
      [Anderson (Boot. Não Paramétrico)], [3.42082], [0.08139], [3.26091], [3.58338], [0.32247],
    ),
    supplement: [Tabela]
  )<tab:bootstrap>
]

A comparação dos intervalos de confiança revela que o intervalo obtido via bootstrap paramétrico de Anderson é o mais estreito (largura de $0.31775$), seguido pelo não paramétrico ($0.32247$), enquanto o intervalo de casos completos (CC) é o mais largo ($0.32574$).

Esse comportamento era teoricamente esperado por dois motivos principais. Primeiro, o estimador de Anderson incorpora a informação das 35 observações parciais de radiação solar, aumentando o tamanho de amostra efetivo e reduzindo a variância assintótica em comparação com o método que simplesmente descarta esses dados (CC). Segundo, o bootstrap paramétrico assume a veracidade do modelo normal bivariado (que de fato é o modelo gerador na simulação), o que confere maior eficiência e precisão à estimativa do erro padrão, resultando em um intervalo mais estreito que a variante não paramétrica, que não impõe restrições estruturais sobre a distribuição dos dados.

Contudo, observa-se que as larguras de todos os intervalos de confiança obtidos são muito parecidas (diferindo por menos de $0.008$ na amplitude). Isso também é esperado e decorre da propagação de incerteza descrita pela fórmula analítica do erro padrão do estimador de Anderson para a média da variável incompleta $mu_2$:
$ "EP"(hat(mu)_2^"MV") approx sqrt( frac(sigma_(22 dot 1), r) (1 + frac((hat(mu)_1^"MV" - overline(x)_1)^2, s_(11))) + frac(hat(beta)_(21 dot 1)^2 sigma_(11), n) ) $
Na fórmula acima, o intervalo depende diretamente do comportamento e da variabilidade de $Y_1$ (radiação solar). Como os dados de radiação solar apresentam uma dispersão intrínseca extremamente elevada ($sigma_(11) approx 8054.97$), essa alta variabilidade da variável preditora é propagada para o estimador condicional. Consequentemente, a incerteza adicional trazida pela variância de $Y_1$ compensa parte do ganho obtido pelo aumento do tamanho de amostra de $r = 111$ para $n = 146$ observações de radiação solar. Isso explica por que, nos dados reais, os intervalos de confiança resultam em amplitudes tão próximas.

= Simulação de Eficiência Relativa

Para avaliar o desempenho relativo do estimador de máxima verossimilhança de Anderson frente ao estimador de casos completos, conduzi um estudo de simulação sistemático. Avaliei a eficiência relativa (definida pela razão dos erros quadráticos médios, $"EF" = "MSE"(hat(mu)_2^"CC") / "MSE"(hat(mu)_2^"MV")$) variando a correlação populacional $rho$ (de 0.1 a 0.9) e a fração de dados faltantes $p_("miss")$ (de 10% a 55%), sob uma amostra fixada em $N = 200$ e $S = 1.000$ réplicas de Monte Carlo. Os resultados numéricos estão organizados na @tab:eficiencia e visualizados na @fig:eficiencia_rel e na @fig:ganho_ef.

#align(center)[
  #figure(
    table(
      columns: (auto, auto, auto, auto, auto),
      inset: 10pt,
      align: (left, right, right, right, right),
      [*Correlação ($rho$)*], [*$p_("miss") = 0.10$*], [*$p_("miss") = 0.25$*], [*$p_("miss") = 0.40$*], [*$p_("miss") = 0.55$*],
      [0.1], [1.006], [1.016], [1.017], [0.977],
      [0.3], [1.032], [1.216], [1.422], [1.840],
      [0.5], [1.097], [1.706], [2.711], [3.986],
      [0.7], [1.178], [2.480], [4.600], [8.349],
      [0.9], [1.434], [3.398], [8.528], [18.651]
    ),
    supplement: [Tabela]
  )<tab:eficiencia>
]

#figure(
  image("../images/eficiencia_relativa.png", width: 70%),
  caption: [Superfície de eficiência relativa (MSE_CC / MSE_Anderson) em função da fração de dados faltantes (p_miss) e da correlação rho.]
) <fig:eficiencia_rel>

#figure(
  image("../images/ganho_estimadores_em_funcao_de_p_e_p_miss.png", width: 60%),
  caption: [Ganho de eficiência do estimador de Anderson versus CC plotado contra a correlação populacional para diferentes patamares de perda de dados.]
) <fig:ganho_ef>

Os resultados revelam que a eficiência relativa do estimador de Anderson é maior que 1 em quase todos os cenários (exceto na região de correlação quase nula $rho = 0.1$ combinada com alta perda de dados, onde flutuações amostrais na simulação podem levar a valores discretamente abaixo de 1).

O ganho de eficiência do estimador de máxima verossimilhança de Anderson é uma função fortemente crescente de duas quantidades do modelo:
1. *A correlação populacional ($rho$)*: Quando as variáveis são fracamente correlacionadas ($rho = 0.1$), conhecer a radiação solar fornece pouca ou nenhuma informação sobre a concentração de ozônio. Nesse caso, a eficiência de Anderson é próxima a 1. À medida que a correlação cresce, a relação de regressão condicional torna-se extremamente forte, permitindo que os dados observados de radiação estimem com grande precisão a porção ausente do ozônio.
2. *A fração de dados faltantes ($p_("miss")$)*: Quanto maior a proporção de dados parciais, maior é o desperdício de informação provocado pelo estimador CC, que joga fora uma parcela massiva da amostra. Em contrapartida, o estimador de Anderson retém a informação da variável completa, capitalizando sobre o tamanho amostral total de $Y_1$.

Desse modo, o regime no qual o ganho de eficiência do estimador de Anderson é máximo corresponde ao cenário de *alta correlação* e *alta fração de dados faltantes*. Sob $rho = 0.9$ e $p_("miss") = 0.55$, o estimador de Anderson atinge uma eficiência extraordinária de $18.651$ em relação ao de casos completos. Esse resultado prático evidencia o potencial da modelagem por máxima verossimilhança na presença de dados faltantes estruturados.

#pagebreak()

= Apêndice

== Provas Matemáticas da Fatoração da Verossimilhança <apendice:provas>

=== 1. Fatoração da Densidade Conjunta da Normal Bivariada

Seja $(Y_(i, 1), Y_(i, 2))^T ~ N_2(mu, Sigma)$ com vetor de médias e matriz de covariâncias dados por:
$ mu = mat(mu_1; mu_2), quad Sigma = mat(sigma_(11), sigma_(12); sigma_(12), sigma_(22)) $

A densidade conjunta de $(Y_(i, 1), Y_(i, 2))$ pode ser fatorada pela definição de probabilidade condicional:
$ f(y_(i, 1), y_(i, 2) mid mu, Sigma) = f_1(y_(i, 1) mid mu_1, sigma_(11)) dot f_2(y_(i, 2) mid y_(i, 1), beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1)) $

Pelas propriedades da normal multivariada, a distribuição marginal de $Y_(i, 1)$ é univariada normal:
$ Y_(i, 1) ~ N(mu_1, sigma_(11)) $
$ f_1(y_(i, 1)) = frac(1, sqrt(2 pi sigma_(11))) exp( - frac((y_(i, 1) - mu_1)^2, 2 sigma_(11)) ) $

A distribuição condicional de $Y_(i, 2)$ dado $Y_(i, 1) = y_(i, 1)$ é:
$ Y_(i, 2) mid Y_(i, 1) = y_(i, 1) ~ N( mu_2 + frac(sigma_(12), sigma_(11)) (y_(i, 1) - mu_1), quad sigma_(22) - frac(sigma_(12)^2, sigma_(11)) ) $

Escrevendo a média condicional na forma de uma função de regressão linear:
$ E(Y_(i, 2) mid Y_(i, 1)) = beta_(20 dot 1) + beta_(21 dot 1) Y_(i, 1) $

Defino os parâmetros da regressão condicional como:
$ beta_(21 dot 1) = frac(sigma_(12), sigma_(11)) $
$ beta_(20 dot 1) = mu_2 - beta_(21 dot 1) mu_1 $
$ sigma_(22 dot 1) = sigma_(22) - beta_(21 dot 1)^2 sigma_(11) = sigma_(22) - frac(sigma_(12)^2, sigma_(11)) $

Portanto, a densidade condicional é:
$ f_2(y_(i, 2) mid y_(i, 1)) = frac(1, sqrt(2 pi sigma_(22 dot 1))) exp( - frac((y_(i, 2) - beta_(20 dot 1) - beta_(21 dot 1) y_(i, 1))^2, 2 sigma_(22 dot 1)) ) $

=== 2. Bijetividade da Reparametrização

Defino o vetor de parâmetros original por $theta = (mu_1, mu_2, sigma_(11), sigma_(12), sigma_(22))^T$ e o vetor reparametrizado por $phi = (mu_1, sigma_(11), beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1))^T$. As relações que definem a transformação direta de $theta$ para $phi$ foram apresentadas no item anterior.

Para provar a bijetividade, mostro que a transformação inversa é dada de forma única pelas equações:
$ mu_1 = mu_1 $
$ sigma_(11) = sigma_(11) $
$ sigma_(12) = beta_(21 dot 1) sigma_(11) $
$ mu_2 = beta_(20 dot 1) + beta_(21 dot 1) mu_1 $
$ sigma_(22) = sigma_(22 dot 1) + beta_(21 dot 1)^2 sigma_(11) $

Como as relações diretas e inversas são unicamente determinadas e contínuas no suporte dos parâmetros (onde as variâncias são positivas e a matriz de covariância é definida positiva), a reparametrização de $theta$ para $phi$ é uma função bijetora.

=== 3. Fatoração da Log-Verossimilhança dos Dados Observados

Sob um padrão de dados faltantes aproximadamente monotônico com mecanismo MAR, tenho $Y_(i, 1)$ observado para $i = 1, dots, n$ e $Y_(i, 2)$ observado apenas para $i = 1, dots, r$ (com $r < n$). A verossimilhança observada dos dados conjuntos é dada por:
$ L(phi mid Y_"obs") = product_(i=1)^(r) f(y_(i, 1), y_(i, 2) mid phi) dot product_(i=r+1)^(n) f_1(y_(i, 1) mid phi) $

Aplicando a fatoração da densidade conjunta nos $r$ termos completos:
$ L(phi mid Y_"obs") = product_(i=1)^(r) [ f_1(y_(i, 1) mid mu_1, sigma_(11)) dot f_2(y_(i, 2) mid y_(i, 1), beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1)) ] dot product_(i=r+1)^(n) f_1(y_(i, 1) mid mu_1, sigma_(11)) $

Reagrupando os termos marginais de $f_1$:
$ L(phi mid Y_"obs") = product_(i=1)^(n) f_1(y_(i, 1) mid mu_1, sigma_(11)) dot product_(i=1)^(r) f_2(y_(i, 2) mid y_(i, 1), beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1)) $

Aplicando o logaritmo, a log-verossimilhança observada decompõe-se na soma aditiva:
$ ell(phi mid Y_"obs") = ell_1(mu_1, sigma_(11)) + ell_2(beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1)) $

onde:
$ ell_1(mu_1, sigma_(11)) = -frac(n, 2) ln sigma_(11) - frac(1, 2 sigma_(11)) sum_(i=1)^(n) (y_(i, 1) - mu_1)^2 $
$ ell_2(beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1)) = -frac(r, 2) ln sigma_(22 dot 1) - frac(1, 2 sigma_(22 dot 1)) sum_(i=1)^(r) (y_(i, 2) - beta_(20 dot 1) - beta_(21 dot 1) y_(i, 1))^2 $

=== 4. Independência e Derivação dos Estimadores de Máxima Verossimilhança

Como o vetor de parâmetros da log-verossimilhança observada foi dividido em dois subconjuntos disjuntos e variação-independentes, $(mu_1, sigma_(11))$ e $(beta_(20 dot 1), beta_(21 dot 1), sigma_(22 dot 1))$, a maximização global do log-verossimilhança aditivo pode ser conduzida maximizando $ell_1$ e $ell_2$ de forma independente.

=== Maximização de $ell_1$ (usando todos os $n$ casos):
Calculo a derivada parcial em relação a $mu_1$ e igualo a zero:
$ frac(partial ell_1, partial mu_1) = frac(1, sigma_(11)) sum_(i=1)^(n) (y_(i, 1) - mu_1) = 0 ==> hat(mu)_1^"MV" = frac(1, n) sum_(i=1)^(n) y_(i, 1) $

Em seguida, derivo em relação a $sigma_(11)$ e igualo a zero:
$ frac(partial ell_1, partial sigma_(11)) = -frac(n, 2 sigma_(11)) + frac(1, 2 sigma_(11)^2) sum_(i=1)^(n) (y_(i, 1) - mu_1)^2 = 0 ==> hat(sigma)_(11)^"MV" = frac(1, n) sum_(i=1)^(n) (y_(i, 1) - hat(mu)_1^"MV")^2 $

=== Maximização de $ell_2$ (usando os $r$ casos completos):
Esta componente corresponde à log-verossimilhança de um modelo de regressão linear normal. A maximização equivale ao procedimento de mínimos quadrados ordinários aplicados ao subconjunto de tamanho $r$. 

Definindo as estatísticas amostrais dos $r$ casos completos:
$ overline(x)_1 = frac(1, r) sum_(i=1)^(r) y_(i, 1), quad overline(y)_2 = frac(1, r) sum_(i=1)^(r) y_(i, 2) $
$ s_(11) = frac(1, r) sum_(i=1)^(r) (y_(i, 1) - overline(x)_1)^2, quad s_(12) = frac(1, r) sum_(i=1)^(r) (y_(i, 1) - overline(x)_1)(y_(i, 2) - overline(y)_2) $

Os estimadores de máxima verossimilhança dos parâmetros da regressão condicional são dados pelas estimativas clássicas de MQO:
$ hat(beta)_(21 dot 1) = frac(s_(12), s_(11)) $
$ hat(beta)_(20 dot 1) = overline(y)_2 - hat(beta)_(21 dot 1) overline(x)_1 $
$ hat(sigma)_(22 dot 1) = frac(1, r) sum_(i=1)^(r) (y_(i, 2) - hat(beta)_(20 dot 1) - hat(beta)_(21 dot 1) y_(i, 1))^2 $

=== Obtenção de $hat(mu)_2^"MV"$:
Pela propriedade de invariância dos estimadores de máxima verossimilhança sob transformações bijetoras, tenho que a média populacional de $Y_2$ pode ser reobtida a partir dos parâmetros condicionais estimados:
$ hat(mu)_2^"MV" = hat(beta)_(20 dot 1) + hat(beta)_(21 dot 1) hat(mu)_1^"MV" $

Substituindo a expressão de $hat(beta)_(20 dot 1)$ na equação:
$ hat(mu)_2^"MV" = (overline(y)_2 - hat(beta)_(21 dot 1) overline(x)_1) + hat(beta)_(21 dot 1) hat(mu)_1^"MV" $
$ hat(mu)_2^"MV" = overline(y)_2 + hat(beta)_(21 dot 1) (hat(mu)_1^"MV" - overline(x)_1) $

Isso completa a prova matemática formal do estimador de máxima verossimilhança de Anderson para dados normalizados.

== Códigos Computacionais Relevantes em R <apendice:codigos>

Para fins de reprodutibilidade, esta seção apresenta as principais rotinas computacionais desenvolvidas em R para a execução das análises e simulações deste relatório.

=== 1. Estimador de Anderson e Algoritmos de Bootstrap

```R
# Função principal para o cálculo do estimador de máxima verossimilhança de Anderson (1957)
anderson_mu2 <- function(y1_all, y2_all, miss1, miss2) {
  comp <- !miss1 & !miss2
  y1_obs <- y1_all[!miss1]
  
  if (sum(comp) < 3 || length(y1_obs) < 3) return(NA_real_)
  
  y1c <- y1_all[comp]; y2c <- y2_all[comp]
  mu1c <- mean(y1c); mu2c <- mean(y2c)
  s11 <- mean((y1c - mu1c)^2)
  s12 <- mean((y1c - mu1c) * (y2c - mu2c))
  
  if (abs(s11) < 1e-12) return(NA_real_)
  
  b21 <- s12 / s11
  mu1_all <- mean(y1_obs)
  return(mu2c + b21 * (mu1_all - mu1c))
}

# Loop do Bootstrap Paramétrico (B = 2.000)
# executado a partir dos parâmetros já estimados (mu_hat e Sigma_hat)
set.seed(42)
B <- 2000
boot_param <- numeric(B)
for (b in seq_len(B)) {
  sim <- mvrnorm(N_total, mu = mu_hat, Sigma = Sigma_hat) # Parâmetros estimados
  boot_param[b] <- anderson_mu2(sim[, 1], sim[, 2], miss_y1, miss_y2)
}
ep_param <- sd(boot_param, na.rm = TRUE)
```

=== 2. Estudo de Simulação de Eficiência Relativa

```R
# Simulação sistemática de Monte Carlo (S = 1.000 réplicas por célula)
rhos    <- c(0.1, 0.3, 0.5, 0.7, 0.9)
p_misss <- c(0.10, 0.25, 0.40, 0.55)
resultados_ef <- expand.grid(rho = rhos, p_miss = p_misss)
resultados_ef$EF_relativa <- NA_real_

for (k in seq_len(nrow(resultados_ef))) {
  rho_k <- resultados_ef$rho[k]
  p_miss_k <- resultados_ef$p_miss[k]
  Sigma_k <- matrix(c(1, rho_k, rho_k, 1), 2, 2)
  n_miss_k <- round(n_ef * p_miss_k)
  
  mse_cc <- numeric(S); mse_mv <- numeric(S)
  for (s in seq_len(S)) {
    dados <- mvrnorm(n_ef, mu = c(0, 0), Sigma = Sigma_k)
    y1 <- dados[, 1]; y2 <- dados[, 2]
    
    # Geração do mecanismo MAR baseado em Y1
    prob_miss <- plogis(-y1)
    prob_miss <- prob_miss / sum(prob_miss) * n_miss_k
    miss_idx  <- sample(n_ef, size = n_miss_k, prob = prob_miss / sum(prob_miss))
    
    m1_s <- rep(FALSE, n_ef); m2_s <- rep(FALSE, n_ef); m2_s[miss_idx] <- TRUE
    
    mse_cc[s] <- (mean(y2[!m2_s]) - 0)^2
    mse_mv[s] <- (anderson_mu2(y1, y2, m1_s, m2_s) - 0)^2
  }
  resultados_ef$EF_relativa[k] <- mean(mse_cc) / mean(mse_mv)
}
```

== Uso de Inteligência Artificial <apendice:ia>

Em consonância com as boas práticas acadêmicas, documento a seguir a integração e os prompts utilizados com assistentes de Inteligência Artificial (*Claude Code* e *ChatGPT*) ao longo deste projeto:

1. *Desenvolvimento de Código (Claude Code)*: O Claude Code foi o assistente principal para o desenvolvimento, depuração e refinamento de todas as rotinas estatísticas em R das questões 1, 2, 3 e Extra, incluindo a modelagem do estimador de Anderson, loops de bootstrap paramétrico/não paramétrico e a grade de simulação de eficiência relativa.
2. *Processamento Estatístico e Diagnóstico (ChatGPT)*: O ChatGPT foi consultado especificamente para indicar métodos formais e pacotes em R voltados ao teste de hipóteses de normalidade multivariada (Mardia, Henze-Zirkler e Royston), uma vez que a viabilidade de testes formais de normalidade conjunta bivariada para dados com perdas não era de meu conhecimento prévio.

=== Prompts de Comando Utilizados por Questão:

-   *Questão 1 (Classificação de Casos Completos e Médias)*:
    - *Prompt*: _"Estou analisando um problema de dados faltantes usando o conjunto de dados 'airquality' do R. As variáveis que me interessam são a radiação solar (Solar.R) e o ozônio (Ozone). Escreva um script em R que classifique cada uma das 153 observações em um dos padrões de dados faltantes: completos (Solar.R e Ozone observados), parciais (Solar.R observado, Ozone faltante), invertidos (Ozone observado, Solar.R faltante) e totalmente ausentes. Depois disso, calcule a média amostral de Solar.R e o seu respectivo erro padrão usando duas amostras: apenas as observações com casos completos de Solar.R e Ozone, e todas as observações onde Solar.R está presente. Compare se as duas estimativas da média diferem numericamente."_ (Claude Code)
    - *Contexto Adicional Enviado*: O esquema de colunas do dataset `airquality` (com as primeiras 6 linhas mostrando os valores de `Ozone` e `Solar.R` e a presença de `NA`) e as definições teóricas da distribuição amostral da média.

-   *Questão 2 (Visualização e Testes de Hipótese)*:
    - *Visualizações e Transformações*:
      - *Prompt*: _"Para o mesmo par de variáveis (Solar.R e Ozone), preciso avaliar visualmente a suposição de normalidade bivariada conjunta para aplicar o estimador de Anderson posteriormente. Escreva um script no R para plotar quatro gráficos de dispersão lado a lado testando as transformações de escala original e logarítmica para cada variável (Y1 vs Y2, Y1 vs log(Y2), log(Y1) vs Y2 e log(Y1) vs log(Y2)). Também gere gráficos de curvas de contorno de densidade kernel conjunta (KDE) usando o pacote 'MASS' para essas mesmas quatro transformações para verificar visualmente qual apresenta contornos mais elípticos."_ (Claude Code)
      - *Contexto Adicional Enviado*: A quantidade de dados completos ($r = 111$) e a especificação de que a transformação logarítmica em $Y_2$ deveria linearizar a relação e estabilizar a variância.
    - *Existência de Testes Formais*:
      - *Prompt*: _"Estou escrevendo um relatório de estatística sobre dados faltantes e normalidade bivariada. O gráfico de dispersão com Y2 transformado em logaritmo sugere que os dados seguem uma normal bivariada, mas eu gostaria de dar mais rigor científico. Não sei se existem testes de hipóteses formais para verificar se dados bivariados ou multivariados seguem uma distribuição normal conjunta ou se existem testes de normalidade multivariada que eu possa aplicar em R. Quais são os nomes desses testes, como eles funcionam teoricamente e quais pacotes e funções eu posso usar em R para aplicá-los ao meu conjunto de dados?"_ (ChatGPT)
      - *Contexto Adicional Enviado*: Os nomes das variáveis transformadas, a hipótese nula clássica do teste de normalidade e a observação de que os testes deveriam tratar a distribuição conjunta.

-   *Questão 3 e Extra (Anderson, Viés sob MAR, Bootstrap e Eficiência)*:
    - *Simulação de Viés sob MAR*:
      - *Prompt*: _"Quero comprovar empiricamente que descartar observações incompletas gera viés sob o mecanismo Missing at Random (MAR). Usando as estimativas de casos completos obtidas nos dados reais como parâmetros 'verdadeiros', escreva um loop de simulação de Monte Carlo com 1.000 réplicas em R. Em cada réplica, gere 153 dados bivariados normais e aplique uma probabilidade de perda de Ozone que seja dependente do nível de Solar.R por meio de uma curva logística (MAR). Calcule a média de Ozone usando apenas casos completos em cada réplica e faça um teste t para provar se a média simulada dos estimadores CC difere significativamente do valor verdadeiro."_ (Claude Code)
      - *Contexto Adicional Enviado*: O modelo de probabilidade logística para o mecanismo MAR e os parâmetros populacionais estimados na questão anterior.
    - *Estimador de Anderson e Bootstrap*:
      - *Prompt*: _"Implemente em R o estimador de máxima verossimilhança de Anderson (1957) para a média da variável com dados faltantes (mu2). A fórmula analítica é mu2_MV = bar(y)2 + beta21 \* (mu1_MV - bar(x)1). Para calcular a incerteza do estimador, crie dois procedimentos de bootstrap com 2.000 réplicas: (1) um bootstrap paramétrico, simulando amostras da distribuição normal bivariada estimada e forçando a mesma estrutura de perda observada, e (2) um bootstrap não paramétrico, reamostrando as linhas originais com reposição. Retorne a média, erro padrão e os intervalos de confiança de 95% para ambos os métodos, comparando com o intervalo analítico t-Student do estimador de casos completos."_ (Claude Code)
      - *Contexto Adicional Enviado*: As definições matemáticas das estimativas amostrais baseadas em subconjuntos (casos completos de tamanho $r$ e dados observados de tamanho $n$) e a fatoração teórica da log-verossimilhança de Anderson.
    - *Grade de Simulação de Eficiência Relativa*:
      - *Prompt*: _"Preciso fazer um estudo de simulação sistemático para avaliar em qual cenário o ganho de eficiência do estimador de Anderson em relação ao de casos completos (CC) é maior. Crie uma grade de simulação variando a correlação populacional rho (de 0.1 a 0.9 em passos de 0.2) e a fração de perdas p_miss (de 10% a 55% em passos de 15%). Para cada uma das 20 combinações, gere 1.000 réplicas sob mecanismo MAR. Calcule a eficiência relativa como a razão dos erros quadráticos médios (MSE_CC / MSE_MV) e organize os resultados finais em uma tabela em R."_ (Claude Code)
      - *Contexto Adicional Enviado*: A especificação de tamanho amostral fixo de 200 observações, o gerador de probabilidades MAR baseado no sinal de Y1 e a fórmula do MSE.
