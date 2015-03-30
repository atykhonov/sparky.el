(require 'thingatpt)
(require 'cl)

(defmacro sparky--define-key (map key function)
  `(lexical-let ((key-map ,map)
                 (func ,function))
     (define-key key-map (kbd ,key) (lambda ()
                                      (interactive)
                                      (run-hooks 'sparky-enter-hook)
                                      (set-transient-map key-map nil
                                                         (lambda ()
                                                           (run-hooks 'sparky-quit-hook)))
                                      (funcall func)))))

(defvar sparky-enter-hook nil)

(defvar sparky-quit-hook nil)

(defvar sparky-forward-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "x" 'forward-sentence)
    (sparky--define-key map "n" 'next-line)
    (sparky--define-key map "f" 'forward-word)
    (sparky--define-key map "s" 'forward-sexp)
    (sparky--define-key map "y" (lambda ()
                                  (interactive)
                                  (forward-symbol 1)))
    (sparky--define-key map "u" 'up-list)
    (sparky--define-key map "i" 'down-list)
    (sparky--define-key map "l" 'forward-list)
    (sparky--define-key map "c" 'forward-sentence)
    (sparky--define-key map "." 'sparky-undo-last-command)
    (sparky--define-key map "," 'sparky-adjust-last-command)
    (sparky--define-key map "." 'sparky-undo-last-command)
    (sparky--define-key map "," 'sparky--adjust-last-command)
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "b" 'sparky-backward)
    (sparky--define-key map "p" 'sparky-backward)
    ;; ("a" beginning/body "Turn on beginning mode." :exit t)
    ;; ("e" end/body "Turn on end mode." :exit t)
    (sparky--define-key map "k" 'sparky-mark)
    (sparky--define-key map "a" 'sparky-beginning)
    ;; ("d" kill-word/body "Turn on kill-word mode." :exit t)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defvar sparky-backward-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "p" 'previous-line)
    (sparky--define-key map "b" 'backward-word)
    (sparky--define-key map "s" 'backward-sexp)
    (sparky--define-key map "u" 'backward-up-list)
    (sparky--define-key map "l" 'backward-list)
    (sparky--define-key map "c" 'backward-sentence)
    (sparky--define-key map "." 'sparky-undo-last-command)
    (sparky--define-key map "," 'sparky-adjust-last-command)
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "f" 'sparky-forward)
    (sparky--define-key map "n" 'sparky-forward)
    (sparky--define-key map "a" 'sparky-beginning)
    ;; ("a" beginning/body "Turn on beginning mode." :exit t)
    ;; ("e" end/body "Turn on end mode." :exit t)
    (sparky--define-key map "k" 'sparky-mark)
    ;; ("d" kill-word/body "Turn on kill-word mode." :exit t)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defvar sparky-mark-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "k" (lambda ()
                                  (interactive)
                                  (let ((pos (point)))
                                    (if (region-active-p)
                                        (progn
                                          (if (eolp)
                                              (beginning-of-line-text 2)
                                            (end-of-line)))
                                      (progn
                                        (if (eolp)
                                            (progn
                                              (set-mark-command nil)
                                              (beginning-of-line-text 2))
                                          (progn
                                            (set-mark-command nil)
                                            (end-of-line))))))))
    (sparky--define-key map "o" (lambda ()
                                  (interactive)
                                  (let ((pos (point)))
                                    (if (region-active-p)
                                        (beginning-of-line 2)
                                      (progn
                                        (beginning-of-line)
                                        (set-mark-command nil)
                                        (end-of-line))))))
    (sparky--define-key map "r" (lambda ()
                                  (interactive)
                                  (kill-region (region-beginning) (region-end) '(4))))
    (sparky--define-key map "c" 'kill-rectangle)
    (sparky--define-key map "s" (lambda ()
                                  (interactive)
                                  (sparky-mark-thing-at-point 'sexp)))
    (sparky--define-key map "w" (lambda ()
                                  (interactive)
                                  (sparky-mark-thing-at-point 'word)))
    (sparky--define-key map "h" (lambda ()
                                  (interactive)
                                  (delete-horizontal-space)))
    (sparky--define-key map "m" 'forward-word)
    (sparky--define-key map "t" (lambda ()
                                  (interactive)
                                  (just-one-space)))
    (sparky--define-key map ")" (lambda ()
                                  (interactive)
                                  (if (region-active-p)
                                      (sparky-mark-string "(" ")" t)
                                    (sparky-mark-string "(" ")" nil))))
    (sparky--define-key map "-" (lambda ()
                                  (interactive)
                                  (sparky-mark-string " " " " nil)))
    (sparky--define-key map "'" (lambda ()
                                  (interactive)
                                  (if (region-active-p)
                                      (sparky-mark-string "'" "'" t)
                                    (sparky-mark-string "'" "'" nil))))
    (sparky--define-key map "\"" (lambda ()
                                   (interactive)
                                   (if (region-active-p)
                                       (sparky-mark-string "\"" "\"" t)
                                     (sparky-mark-string "\"" "\"" nil))))
    (sparky--define-key map "z" (lambda (char)
                                  (interactive "cCharacter: ")
                                  (let ((start (point))
                                        (end (search-forward (char-to-string char))))
                                    (goto-char start)
                                    (set-mark-command nil)
                                    (goto-char (- end 1)))))
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "f" 'sparky-forward)
    (sparky--define-key map "n" 'sparky-forward)
    (sparky--define-key map "b" 'sparky-backward)
    (sparky--define-key map "p" 'sparky-backward)
    (sparky--define-key map "a" 'sparky-beginning)
    ;; ("e" end/body "Turn on end mode." :exit t)
    ;; ("d" kill-word/body "Turn on kill-word mode." :exit t)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defvar sparky-beginning-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "a" 'beginning-of-line)
    (sparky--define-key map "r" 'beginning-of-buffer)
    (sparky--define-key map "s" (lambda ()
                                  (interactive)
                                  (beginning-of-sexp)))
    (sparky--define-key map "u" 'beginning-of-defun)
    (sparky--define-key map "l" 'beginning-of-line-text)
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "f" 'sparky-forward)
    (sparky--define-key map "b" 'sparky-backward)
    (sparky--define-key map "n" 'sparky-forward)
    (sparky--define-key map "p" 'sparky-backward)
    (sparky--define-key map "e" 'sparky-end)
    (sparky--define-key map "k" 'sparky-mark)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defvar sparky-end-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "e" 'end-of-line)
    (sparky--define-key map "r" 'end-of-buffer)
    (sparky--define-key map "s" (lambda ()
                                  (interactive)
                                  (end-of-sexp)))
    (sparky--define-key map "u" 'end-of-defun)
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "f" 'sparky-forward)
    (sparky--define-key map "b" 'sparky-backward)
    (sparky--define-key map "n" 'sparky-forward)
    (sparky--define-key map "p" 'sparky-backward)
    (sparky--define-key map "a" 'sparky-beginning)
    (sparky--define-key map "k" 'sparky-mark)
    ;; (sparky--define-key map "d" 'kill-word)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defvar sparky-mark-forward-map
  (let ((map (make-sparse-keymap)))
    (sparky--define-key map "d" (lambda ()
                                  (interactive)
                                  (mark-word nil t)))
    (sparky--define-key map "s" (lambda ()
                                  (interactive)
                                  (mark-sexp nil t)))
    (sparky--define-key map "c" (lambda ()
                                  (interactive)
                                  (mark-end-of-sentence 1)))
    ;; quick shortcuts to the other modes:
    (sparky--define-key map "f" 'sparky-forward)
    (sparky--define-key map "b" 'sparky-backward)
    (sparky--define-key map "a" 'sparky-beginning)
    (sparky--define-key map "e" 'sparky-end)
    (sparky--define-key map "k" 'sparky-mark)
    (define-key map (kbd "g") 'sparky-keyboard-quit)
    map))

(defun sparky-keyboard-quit ()
  (interactive)
  (run-hooks 'sparky-quit-hook)
  (keyboard-escape-quit))

(defvar sparky-last-command nil)

(defun sparky-adjust-last-command ()
  (interactive)
  (let ((previous-command (nth 0 sparky-last-command)))
    (when (not (null sparky-last-command))
      (cond ((eq previous-command 'backward-word) (forward-word))
            ((eq previous-command 'backward-sexp) (forward-sexp))
            ((eq previous-command 'forward-word) (backward-word))
            ((eq previous-command 'forward-sexp) (backward-sexp))))))

(defun sparky-undo-last-command ()
  (interactive)
  (let ((previous-command (nth 0 sparky-last-command)))
    (when (not (null sparky-last-command))
      (cond ((eq previous-command 'backward-word) (progn (forward-word 2) (backward-word)))
            ((eq previous-command 'backward-sexp) (progn (forward-sexp 2) (backward-sexp)))
            ((eq previous-command 'forward-word) (progn (backward-word 2) (forward-word)))
            ((eq previous-command 'forward-sexp) (progn (backward-sexp 2) (forward-sexp)))))))

(defun sparky-mark-thing-at-point (thing)
  (let ((bounds (bounds-of-thing-at-point thing)))
    (goto-char (car bounds))
    (set-mark-command nil)
    (goto-char (cdr bounds))))

(defun sparky-mark-string (char1 char2 hungry)
  (let ((start nil)
        (end nil))
    (save-excursion
      (setq start (search-backward char1))
      (when (null hungry)
        (setq start (+ start 1))))
    (save-excursion
      (setq end (search-forward char2))
      (when (null hungry)
        (setq end (- end 1))))
    (goto-char start)
    (set-mark-command nil)
    (goto-char end)))

(defun sparky-forward ()
  (interactive)
  (set-transient-map sparky-forward-map))

(defun sparky-backward ()
  (interactive)
  (set-transient-map sparky-backward-map))

(defun sparky-mark ()
  (interactive)
  (set-transient-map sparky-mark-map))

(defun sparky-mark-forward ()
  (interactive)
  (set-transient-map sparky-mark-forward-map))

(defun sparky-beginning ()
  (interactive)
  (set-transient-map sparky-beginning-map))

(defun sparky-end ()
  (interactive)
  (set-transient-map sparky-end-map))

(global-set-key (kbd "M-f") 'sparky-forward)
(global-set-key (kbd "M-b") 'sparky-backward)
(global-set-key (kbd "C-p") 'sparky-forward)
(global-set-key (kbd "C-n") 'sparky-backward)
(global-set-key (kbd "C-k") 'sparky-mark)
(global-set-key (kbd "M-d") 'sparky-mark-forward)
(global-set-key (kbd "C-a") 'sparky-beginning)
(global-set-key (kbd "C-e") 'sparky-end)


(provide 'sparky)
