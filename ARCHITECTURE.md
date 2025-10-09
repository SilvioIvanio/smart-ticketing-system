flowchart LR
  subgraph Clients
    P[Passenger App/CLI]
    V[Validator Device]
    A[Admin Console]
  end

  subgraph Services
    PS[Passenger Service]
    TR[Transport Service]
    TK[Ticketing Service]
    PM[Payment Service]
    NS[Notification Service]
    AD[Admin Service]
  end

  subgraph Infra
    K[(Kafka)]
    M[(MongoDB)]
  end

  P-->PS
  P-->TK
  V-->TK
  A-->AD
  A-->TR

  TK<-->M
  PS<-->M
  TR<-->M
  AD<-->M
  PM<-->M
  NS<-->M

  TK-- ticket.requests -->K
  PM-- payments.processed -->K
  AD-- schedule.updates -->K
  TR-- schedule.updates -->K
  TK-- ticket.events -->K
  NS-- consume all -->K
