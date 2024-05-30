;;;; algoritmo.lisp
;;;; Contém a implementação do algoritmo de jogo independente do domínio
;;;; Autores: 202100230 - Pedro Anjos, 202100225 - André Meseiro

(in-package :5)

;;; Variáveis globais
(defvar *nos-gerados* 0)
(defvar *nos-expandidos* 0)
(defvar *cortes-realizados* 0)

;;; Construtor

;; Cria um nó com o estado, a profundidade e o nó pai
(defun cria-no (estado &optional (g 0) (pai nil))
  "Cria um nó com o estado, o custo e o nó pai"
  (list estado g pai)
)

;;; Seletores

;; Retorna o estado do nó dado como argumento
(defun no-estado (no)
  "Retorna o estado do nó dado como argumento"
  (first no)
)

;; Retorna o custo do nó dado como argumento
(defun no-profundidade (no)
  "Retorna o custo do nó dado como argumento"
  (second no)
)

;; Retorna o nó pai do nó dado como argumento
(defun no-pai (no)
  "Retorna o nó pai do nó dado como argumento"
  (third no)
)

;; Função negamax com cortes alfabeta que recebe um nó, uma profundidade, um alfa, um beta, um jogador, uma lista de jogadores, uma função de sucessores e uma função de avaliação 
;; e retorna o valor do nó
(defun negamax (no profundidade alfa beta jogador jogadores funcao-sucessores funcao-avaliacao &optional (cache (make-hash-table)) (limite 5000) (folga 50) (tempo-inicial (get-internal-real-time)))
  "Função negamax com cortes alfabeta"
  (let ((sucessores (funcall funcao-sucessores no jogador)))
    (setf *nos-gerados* (+ *nos-gerados* (length sucessores)))
    (setf *nos-expandidos* (+ *nos-expandidos* 1))
    (cond ((or (zerop profundidade))
            (list no (* (cond ((equal jogador (first jogadores)) 1) (t -1)) (procurar-cache (no-estado no) jogador funcao-avaliacao cache))))
          (t (cond ((null sucessores) nil)
                   (t (negamax-auxiliar no sucessores profundidade alfa beta jogador jogadores funcao-sucessores funcao-avaliacao cache limite folga tempo-inicial))
              )
          )
        )
    )
)

;; Função auxiliar do negamax
(defun negamax-auxiliar (no sucessores profundidade alfa beta jogador jogadores funcao-sucessores funcao-avaliacao cache limite folga tempo-inicial &aux (tempo-atual (get-internal-real-time)))
  "Função auxiliar do negamax"
  (cond ((null sucessores) nil)
        ((>= (* (/ (- tempo-atual tempo-inicial) internal-time-units-per-second) 1000) (- limite folga)) nil)
        (t (let* ((valor (inverter-sinal-utilidade (negamax (car sucessores) (1- profundidade) (- beta) (- alfa) (trocar-jogador jogador jogadores) jogadores funcao-sucessores funcao-avaliacao cache limite folga tempo-inicial))))
                 (cond ((>= (max alfa (cond ((null (second valor)) most-negative-double-float) (t (second valor)))) beta) (progn (setf *cortes-realizados* (+ *cortes-realizados* 1)) nil))
                    (t (no-max-utilidade (append (list valor) (list (negamax-auxiliar no (cdr sucessores) profundidade (max alfa (cond ((null (second valor)) most-negative-double-float) (t (second valor)))) beta jogador jogadores funcao-sucessores funcao-avaliacao cache limite folga tempo-inicial))) jogador))
              )
            )
        )
  )
)

;; Função alfa-beta que executa o negamax com cortes alfa-beta e retorna o valor do nó e o tempo de execução
(defun alfabeta (no profundidade alfa beta jogador jogadores funcao-sucessores funcao-avaliacao &optional (cache (make-hash-table)) (limite 5000) (folga 10) (tempo-inicial (get-internal-real-time)))
  "Função alfa-beta que executa o negamax com cortes alfa-beta e retorna o valor do nó e o tempo de execução"
  (setf *nos-gerados* 0)
  (setf *nos-expandidos* 0)
  (setf *cortes-realizados* 0)
  (let* ((jogada-calculada (negamax no profundidade alfa beta jogador jogadores funcao-sucessores funcao-avaliacao cache limite folga tempo-inicial))
         (jogada (jogada-a-realizar no (first jogada-calculada))))
    (list (no-estado jogada) (no-profundidade (first jogada-calculada)) (second jogada-calculada) (/ (- (get-internal-real-time) tempo-inicial) internal-time-units-per-second) *nos-expandidos* *nos-gerados* *cortes-realizados*)
  )
)

;; Função que procura na cache
(defun procurar-cache (estado jogador funcao-avaliacao cache)
  "Função que procura na cache"
  (let ((utilidade (gethash estado cache)))
    (cond ((null utilidade) 
            (let ((nova-utilidade (funcall funcao-avaliacao estado jogador)))
              (setf (gethash estado cache) nova-utilidade)
              nova-utilidade
            )
          )
          (t utilidade)
    )
  )
)

;; Função que retorna o nó com a maior utilidade e a sua utilidade
(defun no-max-utilidade (lista jogador &optional max-util)
  "Função que retorna o nó com a maior utilidade e a sua utilidade"
    (cond ((null lista) max-util)
        ((null (car lista)) (no-max-utilidade (cdr lista) jogador max-util))
        ((null max-util) (no-max-utilidade (cdr lista) jogador (car lista)))
        ((> (second (car lista)) (second max-util)) (no-max-utilidade (cdr lista) jogador (car lista)))
        (t (no-max-utilidade (cdr lista) jogador max-util))
  )
)

;; Função que inverte o sinal da utilidade
(defun inverter-sinal-utilidade (utilidade)
  "Função que inverte o sinal da utilidade"
  (cond ((null utilidade) nil)
        (t (list (first utilidade) (- (second utilidade))))
  )
)

;; Função que altera o jogador atual.
(defun trocar-jogador (jogador-atual jogadores)
  "Função que altera o jogador atual"
  (cond ((equal jogador-atual (first jogadores)) (second jogadores))
        ((equal jogador-atual (second jogadores)) (first jogadores))
  )
)

;; Função que recebe o nó atual, o nó que foi caculado e retorna a jogada a realizar.
(defun jogada-a-realizar (no-atual no-calculado)
  "Função que retorna a jogada a realizar"
  (cond ((or (null no-atual) (null no-calculado)) nil)
        ((equal no-atual (no-pai no-calculado)) no-calculado)
        (t (jogada-a-realizar no-atual (no-pai no-calculado)))
  )
)