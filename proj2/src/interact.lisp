;;;; interact.lisp
;;;; Carrega os outros ficheiros de código, escreve e lê de ficheiros e trata da interação com o utilizador
;;;; Autores: 202100230 - Pedro Anjos, 202100225 - André Meseiro

(defpackage :5
  (:use 
    :cl
    :cl-user
  )
)

(defpackage :testes
  (:use 
    :cl
    :cl-user
    :5)
)

(in-package :5)

;;; Carregar ficheiros de código e definir funções necessárias

;; Função que inicializa o programa
(defun inicializar ()
  "Inicializa o programa"
  (format t ";; A carregar ficheiros...~%")
  (cond ((not (null *load-pathname*)) (progn (carregar-componentes *load-pathname*) (format t ";; Ficheiros carregados.~%")))
        ((not (null *compile-file-pathname*)) (progn (carregar-componentes *compile-file-pathname*) (format t ";; Ficheiros carregados.~%")))
        (t (error "Falha ao carregar ficheiros!~%"))
  )
)

;; Função que carrega a função caminho-raiz
(defun carregar-funcao-caminho-raiz (caminho)
  "Carrega a função caminho-raiz"
  (defun caminho-raiz ()
    "Retorna o caminho raiz do projeto"
    (make-pathname :directory (pathname-directory (merge-pathnames "../" caminho )))
  )
)

;; Função que carrega todos os ficheiros de código e
;; define as funções necessárias
(defun carregar-componentes (caminho)
  "Carrega todos os ficheiros de código e define as funções necessárias"
  (carregar-funcao-caminho-raiz caminho)
  (carregar-ficheiros-codigo)
  (carregar-ficheiros-teste)
)

;; Função que carrega os ficheros de código
(defun carregar-ficheiros-codigo ()
  "Carrega os ficheiros de código"
  (load (merge-pathnames "src/jogo.lisp" (caminho-raiz)) :verbose nil)
  (load (merge-pathnames "src/algoritmo.lisp" (caminho-raiz)) :verbose nil)
)

;; Função que carrega os ficheiros de teste
(defun carregar-ficheiros-teste ()
  "Carrega os ficheiros de teste"
  (load (merge-pathnames "t/testes.lisp" (caminho-raiz)) :verbose nil)
)

;;; Funções de jogo

;; Função que recebe um estado e retorna o estado resultante da jogada do computador
(defun jogar (estado tempo &optional (cache (make-hash-table)))
  "Função que recebe um estado e retorna o estado resultante da jogada do computador"
  (alfabeta (cria-no estado) 10 most-negative-double-float most-positive-double-float *cavalo-branco* (list *cavalo-branco* *cavalo-preto*) 'sucessores 'avaliar-estado cache tempo)
)

;;; Funções de interação com o utilizador

;; Função que inicia o jogo
(defun iniciar (&optional (cache (make-hash-table)))
  "Função que inicia o jogo"
  (format t "~46,1,1,'#:@< jogo do cavalo ~>~%#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%")
  (format t "#~44,1,1,:@<1 - humano VS computador~>#~%")
  (format t "#~44,1,1,:@<2 - computador VS computador~>#~%")
  (format t "#~44,1,1,:@<0 - sair da aplicacao~>#~%")
  (format t "#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%~46,1,1,'#:@<~>~%")
  (let ((opcao (ler-opcao 2)))
    (cond ((= opcao 1) (humano-vs-computador cache))
          ((= opcao 2) (computador-vs-computador cache))
          ((= opcao 0) (format t "A sair da aplicacao...~%"))
    )
  )
)

;; Função que inicia o jogo humano vs computador
(defun humano-vs-computador (cache)
  "Função que inicia o jogo humano vs computador"
  (let ((jogadores (jogador-a-comecar)))
    (cond ((null jogadores) (iniciar cache))
          (t (progn (format t "~46,1,1,'#:@< jogadores ~>~%#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%")
                    (format t "#~44,1,1,:@<jogador 1 (~a) - cavalo branco~>#~%" (first (first jogadores)))
                    (format t "#~44,1,1,:@<jogador 2 (~a) - cavalo preto~>#~%" (first (second jogadores)))
                    (format t "#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%~46,1,1,'#:@<~>~%")
                    (let ((tempo-limite (tempo-limite-computador))
                          (tabuleiro (tabuleiro-aleatorio)))
                      (limpar-log-dat)
                      (with-open-file (ficheiro (log-dat) :direction :output :if-exists :supersede :if-does-not-exist :create)
                        (format ficheiro "~46,1,1,'~:@< inicio do jogo ~>~%")
                        (format ficheiro "~46,1,1,'#:@< tabuleiro inicial ~>~%")
                        (escreve-tabuleiro-formatado tabuleiro ficheiro t t 1)
                        (format ficheiro "~46,1,1,'#:@<~>~%~%")
                        (close ficheiro)
                      )
                      (format t "~46,1,1,'~:@< inicio do jogo ~>~%")
                      (format t "~46,1,1,'#:@< tabuleiro inicial ~>~%")
                      (escreve-tabuleiro-formatado tabuleiro t t t 1)
                      (format t "~46,1,1,'#:@<~>~%~%")
                      (ciclo-de-jogo (list tabuleiro (list 0 0)) tempo-limite jogadores cache)
                      (let ((opcao (ler-opcao 1 "Voltar ao menu principal? [sim(1)/nao(0)] > " nil)))
                        (cond ((= opcao 1) (iniciar cache))
                              ((= opcao 0) (format t "A sair da aplicacao...~%"))
                        )
                      )
                    )
              )
          )
    )
  )
)

;; Função que inicia o jogo computador vs computador
(defun computador-vs-computador (cache)
  "Função que inicia o jogo computador vs computador"
  (let ((jogadores (list (list "computador" *cavalo-branco*) (list "computador" *cavalo-preto*))))
    (format t "~46,1,1,'#:@< jogadores ~>~%#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%")
                    (format t "#~44,1,1,:@<jogador 1 (~a) - cavalo branco~>#~%" (first (first jogadores)))
                    (format t "#~44,1,1,:@<jogador 2 (~a) - cavalo preto~>#~%" (first (second jogadores)))
                    (format t "#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%~46,1,1,'#:@<~>~%")
                    (let ((tempo-limite (tempo-limite-computador))
                          (tabuleiro (tabuleiro-aleatorio)))
                      (with-open-file (ficheiro (log-dat) :direction :output :if-exists :supersede :if-does-not-exist :create)
                        (format ficheiro "~%~46,1,1,'~:@< inicio do jogo ~>~%")
                        (format ficheiro "~46,1,1,'#:@< tabuleiro inicial ~>~%")
                        (escreve-tabuleiro-formatado tabuleiro ficheiro t t 1)
                        (format ficheiro "~46,1,1,'#:@<~>~%~%")
                        (close ficheiro)
                      )
                      (format t "~46,1,1,'~:@< inicio do jogo ~>~%")
                      (format t "~46,1,1,'#:@< tabuleiro inicial ~>~%")
                      (escreve-tabuleiro-formatado tabuleiro t t t 1)
                      (format t "~46,1,1,'#:@<~>~%~%")
                      (ciclo-de-jogo (list tabuleiro (list 0 0)) tempo-limite jogadores cache)
                      (let ((opcao (ler-opcao 1 "Voltar ao menu principal? [sim(1)/nao(0)] > " nil)))
                        (cond ((= opcao 1) (iniciar cache))
                              ((= opcao 0) (format t "A sair da aplicacao...~%"))
                        )
                      )
                    )
  )
)

;; Função que representa o ciclo de jogo
(defun ciclo-de-jogo (estado tempo jogadores cache &optional jogador-passou)
  "Função que representa o ciclo de jogo"
  (cond ((equal (first (first jogadores)) "humano")
          (let ((jogada (jogada-humano estado (first jogadores))))
            (cond ((and (null jogada) jogador-passou) (calcular-vitoria estado))
                  ((null jogada) (ciclo-de-jogo estado tempo (reverse jogadores) cache t))
                  (t (ciclo-de-jogo jogada tempo (reverse jogadores) cache))
            )
          )
        )
        (t (let ((jogada (jogada-computador estado tempo (first jogadores) cache)))
             (cond ((and (null jogada) jogador-passou) (calcular-vitoria estado))
                   ((null jogada) (ciclo-de-jogo estado tempo (reverse jogadores) cache t))
                   (t (ciclo-de-jogo jogada tempo (reverse jogadores) cache))
             )
          )
        )
  )
)


;; Função que verifica as condições de vitória
(defun calcular-vitoria (estado)
  "Função que verifica as condições de vitória"
  (let ((pontos-cavalo-branco (first (second estado)))
        (pontos-cavalo-preto (second (second estado))))
    (cond ((> pontos-cavalo-branco pontos-cavalo-preto) (vitoria-jogador-1 estado))
          ((> pontos-cavalo-preto pontos-cavalo-branco) (vitoria-jogador-2 estado))
          (t (empate estado))
    )
  )
)

;; Função em que o jogador 1 ganha
(defun vitoria-jogador-1 (estado)
  "Função em que o jogador 1 ganha"
  (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
    (format ficheiro "~46,1,1,'.:@< vitoria - jogador 1 ~>~%")
    (format ficheiro "~46,1,1,'#:@< tabuleiro final ~>~%")
    (escreve-tabuleiro-formatado (first estado) ficheiro t t 1)
    (format ficheiro "~46,1,1,'#:@<~>~%")
    (format ficheiro "~46,1,1,'-:@< PONTOS ~>~%")
    (format ficheiro "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
    (format ficheiro "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
    (format ficheiro "~46,1,1,'-:@<~>~%")
    (format ficheiro "~46,1,1,'~:@< fim do jogo ~>")
    (close ficheiro)
  )
  (format t "~46,1,1,'.:@< vitoria - jogador 1 ~>~%")
  (format t "~46,1,1,'#:@< tabuleiro final ~>~%")
  (escreve-tabuleiro-formatado (first estado) t t t 1)
  (format t "~46,1,1,'#:@<~>~%")
  (format t "~46,1,1,'-:@< PONTOS ~>~%")
  (format t "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
  (format t "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
  (format t "~46,1,1,'-:@<~>~%")
  (format t "~46,1,1,'~:@< fim do jogo ~>~%~%")
)

;; Função em que o jogador 2 ganha
(defun vitoria-jogador-2 (estado)
  "Função em que o jogador 2 ganha"
  (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
    (format ficheiro "~46,1,1,'.:@< vitoria - jogador 2 ~>~%")
    (format ficheiro "~46,1,1,'#:@< tabuleiro final ~>~%")
    (escreve-tabuleiro-formatado (first estado) ficheiro t t 1)
    (format ficheiro "~46,1,1,'#:@<~>~%")
    (format ficheiro "~46,1,1,'-:@< PONTOS ~>~%")
    (format ficheiro "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
    (format ficheiro "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
    (format ficheiro "~46,1,1,'-:@<~>~%")
    (format ficheiro "~46,1,1,'~:@< fim do jogo ~>~%~%")
    (close ficheiro)
  )
  (format t "~46,1,1,'.:@< vitoria - jogador 2 ~>~%")
  (format t "~46,1,1,'#:@< tabuleiro final ~>~%")
  (escreve-tabuleiro-formatado (first estado) t t t 1)
  (format t "~46,1,1,'#:@<~>~%")
  (format t "~46,1,1,'-:@< PONTOS ~>~%")
  (format t "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
  (format t "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
  (format t "~46,1,1,'-:@<~>~%")
  (format t "~46,1,1,'~:@< fim do jogo ~>~%~%")
)

;; Função em que há empate
(defun empate (estado)
  "Função em que há empate"
  (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
    (format ficheiro "~46,1,1,'.:@< empate ~>~%")
    (format ficheiro "~46,1,1,'#:@< tabuleiro final ~>~%")
    (escreve-tabuleiro-formatado (first estado) ficheiro t t 1)
    (format ficheiro "~46,1,1,'#:@<~>~%")
    (format ficheiro "~46,1,1,'-:@< PONTOS ~>~%")
    (format ficheiro "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
    (format ficheiro "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
    (format ficheiro "~46,1,1,'-:@<~>~%")
    (format ficheiro "~46,1,1,'~:@< fim do jogo ~>~%~%")
    (close ficheiro)
  )
  (format t "~46,1,1,'.:@< empate ~>~%")
  (format t "~46,1,1,'#:@< tabuleiro final ~>~%")
  (escreve-tabuleiro-formatado (first estado) t t t 1)
  (format t "~46,1,1,'#:@<~>~%")
  (format t "~46,1,1,'-:@< PONTOS ~>~%")
  (format t "~46,1,1,' :@<jogador 1 - ~a pts~>~%" (first (second estado)))
  (format t "~46,1,1,' :@<jogador 2 - ~a pts~>~%" (second (second estado)))
  (format t "~46,1,1,'-:@<~>~%")
  (format t "~46,1,1,'~:@< fim do jogo ~>~%~%")
)

;; Função que representa a jogada do humano
(defun jogada-humano (estado jogador-atual)
  (let ((jogador (second jogador-atual)))
    (cond ((not (cavalo-colocado-p jogador (no-estado estado)))
            (let* ((tabuleiro-novo (colocar-cavalo (no-estado estado) jogador))
                   (posicao-destino (posicao-cavalo jogador tabuleiro-novo))
                   (valor-destino (celula (first posicao-destino) (second posicao-destino) (first estado))))
              (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                (format ficheiro "~46,1,1,'.:@< colocar cavalo - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                (format ficheiro "~46,1,1,'#:@< humano ~>~%")
                (escreve-tabuleiro-formatado tabuleiro-novo ficheiro t t 1)
                (format ficheiro "~46,1,1,'#:@<~>~%~%")
                (close ficheiro)
              )
              (format t "~46,1,1,'.:@< colocar cavalo - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
              (format t "~46,1,1,'#:@< humano ~>~%")
              (escreve-tabuleiro-formatado tabuleiro-novo t t t 1)
              (format t "~46,1,1,'#:@<~>~%~%")
              (cond ((equal jogador *cavalo-branco*) (list tabuleiro-novo (list (+ (first (second estado)) valor-destino) (second (second estado)))))
                    ((equal jogador *cavalo-preto*) (list tabuleiro-novo (list (first (second estado)) (+ (second (second estado)) valor-destino))))
              )
            )
          )
          (t (cond ((null (movimentos-possiveis jogador (first estado))) 
                      (progn (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                              (format t "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                              (format t "~46,1,1,'#:@< humano ~>~%")
                              (format t "~46,1,1,'#:@< jogador passou ~>~%~%")
                              (format ficheiro "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                              (format ficheiro "~46,1,1,'#:@< humano ~>~%")
                              (format ficheiro "~46,1,1,'#:@< jogador passou ~>~%~%")
                              (close ficheiro)
                            )
                        nil
                      )
                    )
                   (t (let* ((posicao (jogada-posicao estado jogador))
                            (tabuleiro-novo (mover-cavalo jogador posicao (first estado)))
                            (posicao-destino (posicao-cavalo jogador tabuleiro-novo))
                            (valor-destino (celula (first posicao-destino) (second posicao-destino) (first estado))))
                        (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                          (format ficheiro "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                          (format ficheiro "~46,1,1,'#:@< humano ~>~%")
                          (escreve-tabuleiro-formatado tabuleiro-novo ficheiro t t 1)
                          (format ficheiro "~46,1,1,'#:@<~>~%~%")
                          (close ficheiro)
                        )
                        (format t "~46,1,1,'#:@< humano ~>~%")
                        (escreve-tabuleiro-formatado tabuleiro-novo t t t 1)
                        (format t "~46,1,1,'#:@<~>~%~%")
                        (cond ((equal jogador *cavalo-branco*) (list tabuleiro-novo (list (+ (first (second estado)) valor-destino) (second (second estado)))))
                          ((equal jogador *cavalo-preto*) (list tabuleiro-novo (list (first (second estado)) (+ (second (second estado)) valor-destino))))
                        )
                      )
                   )
              )
          )
    )
  )
)

;; Função que representa a jogada do computador
(defun jogada-computador (estado tempo jogador-atual cache)
  "Função que representa a jogada do computador"
  (let ((jogador (second jogador-atual)))
    (cond ((not (cavalo-colocado-p jogador (no-estado estado)))
            (let* ((novo-tabuleiro (colocar-cavalo (no-estado estado) jogador))
                   (posicao-destino (posicao-cavalo jogador novo-tabuleiro))
                   (valor-destino (celula (first posicao-destino) (second posicao-destino) (first estado))))
              (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                (format ficheiro "~46,1,1,'.:@< colocar cavalo - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                (format ficheiro "~46,1,1,'#:@< computador ~>~%")
                (escreve-tabuleiro-formatado novo-tabuleiro ficheiro t t 1)
                (format ficheiro "~46,1,1,'#:@<~>~%~%")
                (close ficheiro)
              )
              (format t "~46,1,1,'.:@< colocar cavalo - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
              (format t "~46,1,1,'#:@< computador ~>~%")
              (escreve-tabuleiro-formatado novo-tabuleiro t t t 1)
              (format t "~46,1,1,'#:@<~>~%~%")
              (cond ((equal jogador *cavalo-branco*) (list novo-tabuleiro (list (+ (first (second estado)) valor-destino) (second (second estado)))))
                    ((equal jogador *cavalo-preto*) (list novo-tabuleiro (list (first (second estado)) (+ (second (second estado)) valor-destino))))
              )
            )
          )
          (t (let* ((jogador-necessita-troca (cond ((equal jogador *cavalo-branco*) nil) (t t)))
                    (novo-estado (cond (jogador-necessita-troca (trocar-pecas estado)) (t estado)))
                    (jogada (jogar novo-estado tempo cache))
                    (estado-final (cond (jogador-necessita-troca (trocar-pecas (first jogada))) (t (first jogada)))))
                (cond ((null (first jogada)) 
                        (progn (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                                (format t "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                                (format t "~46,1,1,'#:@< computador ~>~%")
                                (format t "~46,1,1,'#:@< jogador passou ~>~%~%")
                                (format ficheiro "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                                (format ficheiro "~46,1,1,'#:@< computador ~>~%")
                                (format ficheiro "~46,1,1,'#:@< jogador passou ~>~%~%")
                                (close ficheiro)
                               )
                          nil
                        )
                      )
                      (t (with-open-file (ficheiro (log-dat) :direction :output :if-exists :append :if-does-not-exist :create)
                            (format t "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                            (format t "~46,1,1,'#:@< computador ~>~%")
                            (escreve-tabuleiro-formatado (first estado-final) t t t 1)
                            (format t "~46,1,1,'#:@<~>~%")
                            (format t "utilidade: ~a~%" (third jogada))
                            (format t "profundidade: ~a~%" (second jogada))
                            (format t "nos expandidos: ~a~%" (fifth jogada))
                            (format t "nos gerados: ~a~%" (sixth jogada))
                            (format t "nos cortados: ~a~%" (seventh jogada))
                            (format t "tempo de execucao: ~3,1f ms~%~%" (* (fourth jogada) 1000.0))
                            (format ficheiro "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal jogador *cavalo-branco*) "1") ((equal jogador *cavalo-preto*) "2")))
                            (format ficheiro "~46,1,1,'#:@< computador ~>~%")
                            (escreve-tabuleiro-formatado (first estado-final) ficheiro t t 1)
                            (format ficheiro "~46,1,1,'#:@<~>~%")
                            (format ficheiro "utilidade: ~a~%" (third jogada))
                            (format ficheiro "profundidade: ~a~%" (second jogada))
                            (format ficheiro "nos expandidos: ~a~%" (fifth jogada))
                            (format ficheiro "nos gerados: ~a~%" (sixth jogada))
                            (format ficheiro "nos cortados: ~a~%" (seventh jogada))
                            (format ficheiro "tempo de execucao: ~3,1f ms~%~%" (* (fourth jogada) 1000.0))
                            (close ficheiro)
                            estado-final
                          )
                      )
                )
              )
          )
    )
  )
)

;; Função que troca as peças dos jogadores
(defun trocar-pecas (estado)
  "Função que troca as peças dos jogadores"
  (let* ((posicao-cavalo-branco (posicao-cavalo *cavalo-branco* (first estado)))
         (posicao-cavalo-preto (posicao-cavalo *cavalo-preto* (first estado)))
         (tabuleiro-branco-trocado (substituir (first posicao-cavalo-preto) (second posicao-cavalo-preto) (first estado) *cavalo-branco*))
         (tabuleiro-preto-trocado (substituir (first posicao-cavalo-branco) (second posicao-cavalo-branco) tabuleiro-branco-trocado *cavalo-preto*)))
    (list tabuleiro-preto-trocado (reverse (second estado)))
  )
)

;; Função que lê a posição para onde mover o cavalo
(defun jogada-posicao (no cavalo)
  "Função que lê a posição para mover onde o cavalo"
  (let ((movimentos (movimentos-possiveis cavalo (no-estado no))))
    (format t "~46,1,1,'.:@< jogada - jogador ~a ~>~%" (cond ((equal cavalo *cavalo-branco*) "1") ((equal cavalo *cavalo-preto*) "2")))
    (format t "Jogadas possiveis (linha coluna):~%")
    (escreve-movimentos-possiveis movimentos)
    (let* ((linha (ler-opcao (length (no-estado no)) "Escolha a linha > " nil))
           (coluna (ler-opcao (length (first (no-estado no))) "Escolha a coluna > ")))
      (cond ((and (integerp coluna) (integerp linha) (lista-contem (list (1- linha) (1- coluna)) movimentos)) (list (1- linha) (1- coluna)))
            (t (progn (format t "valor invalido!~%~%") (jogada-posicao no cavalo)))
      )
    )
  )
)

;; Função que escreve os movimentos possíveis
(defun escreve-movimentos-possiveis (movimentos &optional (i 0))
  "Função que escreve os movimentos possíveis"
  (let ((mov (first movimentos)))
    (cond ((null mov) nil)
          ((equal i 4) (progn (format t "~%") (escreve-movimentos-possiveis movimentos 0)))
          ((equal (length movimentos) 1) (format t "~c~a (~a ~a)~%" (coluna-para-letra (second mov)) (1+ (first mov)) (1+ (first mov)) (1+ (second mov))))
          (t (progn (format t "~c~a (~a ~a), " (coluna-para-letra (second mov)) (1+ (first mov)) (1+ (first mov)) (1+ (second mov))) (escreve-movimentos-possiveis (rest movimentos) (1+ i))))
    )
  )
)

;; Função que lê o tempo limite do computador
(defun tempo-limite-computador (&optional (limite-superior 5000) (limite-inferior 1000))
  "Função que lê o tempo limite do computador"
  (format t "Tempo limite computador [~a,~a](ms) > " limite-inferior limite-superior)
  (let ((valor (read)))
    (cond ((and (integerp valor) (>= valor limite-inferior) (<= valor limite-superior)) (progn (format t "~%") valor))
          (t (progn (format t "valor invalido!~%") (tempo-limite-computador limite-superior limite-inferior)))
    )
  )
)

;; Função que retorna o jogador a começar
(defun jogador-a-comecar ()
  "Função que retorna o jogador a começar"
  (format t "#~44,1,1,'#:@< jogador a comecar ~>#~%#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%")
  (format t "#~44,1,1,:@<1 - humano~>#~%")
  (format t "#~44,1,1,:@<2 - computador~>#~%")
  (format t "#~44,1,1,:@<0 - voltar~>#~%")
  (format t "#~44,1,1,:@<~>#~%#~44,1,1,:@<~>#~%~46,1,1,'#:@<~>~%")
  (let ((opcao (ler-opcao 2 "Escolha o jogador > ")))
    (cond ((= opcao 1) (list (list "humano" *cavalo-branco*) (list "computador" *cavalo-preto*)))
          ((= opcao 2) (list (list "computador" *cavalo-branco*) (list "humano" *cavalo-preto*)))
          ((= opcao 0) nil)
    )
  )
)

;; Função que lê a opção do utilizador
(defun ler-opcao (limite &optional (prompt "Escolha > ") (enter-apos t))
  "Lê a opção do utilizador"
  (format t "~a" prompt)
  (let ((opcao (read)))
    (cond ((and (integerp opcao) (<= 0 opcao limite)) (progn (cond (enter-apos (format t "~%"))) opcao))
          (t (progn (format t "opcao invalida!~%") (ler-opcao limite prompt)))
    )
  )
)

;;; Ficheiro de log

;; Função que retorna o caminho do ficheiro log.dat
(defun log-dat ()
  "Retorna o caminho do ficheiro log.dat"
  (merge-pathnames "log.dat" (caminho-raiz))
)

;; Função que limpa o ficheiro log.dat
(defun limpar-log-dat ()
  "Limpa o ficheiro log.dat"
  (with-open-file (ficheiro (log-dat) :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format ficheiro "")
    (close ficheiro)
  )
)


(inicializar)