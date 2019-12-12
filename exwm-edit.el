;;; exwm-edit.el --- Edit mode for EXWM -*- lexical-binding: t; -*-

;; Author: Ag Ibragimov
;; Maintainer: Junyi Hou
;; URL: https://github.com/junyi-hou/exwm-edit
;; Created: 2018-05-16
;; Focked: 2019-09-04
;; Keywords: convenience
;; License: GPL v3
;; Package-Requires: ((emacs "26.2"))
;; Version: 0.0.1

;;; Commentary:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Similar to atomic-chrome https://github.com/alpha22jp/atomic-chrome
;; except this package is made to work with EXWM https://github.com/ch11ng/exwm
;; and it works with any editable element of any app
;;
;; The idea is very simple - when you press the keybinding,
;; it simulates [C-a (select all) + C-c (copy)],
;; then opens a buffer and yanks (pastes) the content so you can edit it,
;; after you done - it grabs (now edited text) and pastes back to where it's started
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'exwm)

(defcustom exwm-edit-compose-hook nil
  "Customizable hook, runs after `exwm-edit--compose' buffer created."
  :type 'hook
  :group 'exwm-edit)

(defcustom exwm-edit-before-finish-hook nil
  "Customizable hook, runs before `exwm-edit--finish'."
  :type 'hook
  :group 'exwm-edit)

(defcustom exwm-edit-before-cancel-hook nil
  "Customizable hook, runs before `exwm-edit--cancel'."
  :type 'hook
  :group 'exwm-edit)

(defvar exwm-edit--exwm-buffer nil
  "Buffer in which `exwm-edit' is invoked.")

(defun exwm-edit--finish ()
  "Called when done editing buffer created by `exwm-edit--compose'."
  (interactive)
  (run-hooks 'exwm-edit-before-finish-hook)
  (kill-region (point-min)
                 (point-max))
  (kill-buffer-and-window)
  (with-current-buffer exwm-edit--exwm-buffer
    (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
    (run-at-time "0.05 sec" nil (lambda () (exwm-input--fake-key ?\C-v)))
    (setq exwm-edit--exwm-buffer nil)))

(defun exwm-edit--cancel ()
  "Called to cancell editing in a buffer created by `exwm-edit--compose'."
  (interactive)
  (run-hooks 'exwm-edit-before-cancel-hook)
  (kill-buffer-and-window)
  (with-current-buffer exwm-edit--exwm-buffer
    (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
    (exwm-input--fake-key 'right)
    (setq exwm-edit--exwm-buffer nil)))

(defvar exwm-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c '") 'exwm-edit--finish)
    (define-key map (kbd "C-c C-'") 'exwm-edit--finish)
    (define-key map (kbd "C-c C-k") 'exwm-edit--cancel)
    map)
  "Keymap for minor mode `exwm-edit-mode'.")

(define-minor-mode exwm-edit-mode
  "Minor mode enabled in `exwm-edit--compose' buffer"
  :init-value nil
  :lighter " exwm-edit"
  :keymap exwm-edit-mode-map)

(defun exwm-edit--buffer-title (str)
  "`exwm-edit' buffer title based on STR."
  (concat "*exwm-edit " str " *"))

(define-global-minor-mode global-exwm-edit-mode
  exwm-edit-mode exwm-edit--turn-on-edit-mode
  :require 'exwm-edit)

(defun exwm-edit--compose ()
  "Edit text in an EXWM app."
  (interactive)
  (let* ((title (exwm-edit--buffer-title (buffer-name)))
         (existing (get-buffer title))
         ;; FIXME - on second C-c ' `gui-get-selection' will return nil
         (sel (or (gui-get-selection 'PRIMARY 'UTF8_STRING) "")))
    (when (derived-mode-p 'exwm-mode)
      (setq exwm-edit--exwm-buffer (buffer-name))
      (if existing
          (switch-to-buffer-other-window existing)
        (switch-to-buffer-other-window (get-buffer-create title))
        (run-hooks 'exwm-edit-compose-hook)
        (exwm-edit-mode 1)
        (insert sel)
        (setq-local
         header-line-format
         (substitute-command-keys
          "Edit, then exit with `\\[exwm-edit--finish]' or cancel with \ `\\[exwm-edit--cancel]'")))
          )))

(exwm-input-set-key (kbd "C-c '") #'exwm-edit--compose)
(exwm-input-set-key (kbd "C-c C-'") #'exwm-edit--compose)

(provide 'exwm-edit)
;;; exwm-edit.el ends here
