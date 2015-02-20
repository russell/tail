;;; tail.el --- Tail files within Emacs

;; Copyright (C) 2000 by Benjamin Drieu

;; Author: Benjamin Drieu <bdrieu@april.org>
;; Keywords: tools

;; This file is NOT part of GNU Emacs.

;; This program as GNU Emacs are free software; you can redistribute
;; them and/or modify them under the terms of the GNU General Public
;; License as published by the Free Software Foundation; either
;; version 2, or (at your option) any later version.

;; They are distributed in the hope that they will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with them; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;  $Id: tail.el,v 1.2 2010/10/24 16:23:11 benj Exp $

;;; Commentary:

;;  This program displays ``tailed'' contents of files inside
;;  transients windows of Emacs.  It is primarily meant to keep an eye
;;  on logs within Emacs instead of using additional terminals.

;;  This was developed for GNU Emacs 20.x but should work as well for
;;  XEmacs 21.x


;;; Code:

;;  Custom variables (may be set by the user)

;; Functions

(defun tail-disp-window (tail-buffer tail-msg)
  "Display some content specified by ``tail-msg'' inside buffer
``tail-msg''.  Create this buffer if necessary and put it inside a
newly created window on the lowest side of the frame."
  (with-current-buffer tail-buffer
      (let ((goto-eof (eq (point) (point-max))))
        (let ((buffer-read-only nil))
          (save-excursion
            (goto-char (point-max))
            (insert tail-msg)))
        (set-buffer-modified-p nil)
        (when goto-eof
          (if (get-buffer-window tail-buffer t)
              (with-selected-window (get-buffer-window tail-buffer t)
                (goto-char (point-max))
                (let ((this-scroll-margin
                        (min (max 0 scroll-margin)
                             (truncate (/ (window-body-height) 4.0)))))
                  (recenter (- -1 this-scroll-margin))))
            (goto-char (point-max)))))))


(defun tail-file (file)
  "Tails file specified with argument ``file'' inside a new buffer.
``file'' *cannot* be a remote file specified with ange-ftp syntax
because it is passed to the Unix tail command."
  (interactive "Ftail file: ")
  (tail-command "tail" file "-F"))


(defun tail-command (command filename &rest args)
  "Tails command specified with argument ``command'', with
arguments ``args'' inside a new buffer."
  (interactive "sTail command: \neToto: ")
  (let* ((buffer-name (mapconcat 'identity
                                 (concatenate
                                 'list (list "*Tail:" command)
                                 args (list filename "*"))
                                 " "))
         (filename (if (file-remote-p filename)
                       (file-remote-p filename 'localname)
                     filename))
         (buffer (get-buffer-create buffer-name))
         (process
          (start-file-process-shell-command
           command
           buffer-name
           (mapconcat 'identity
                      (concatenate 'list (list command) args (list filename))
                      " "))))
    (with-current-buffer buffer-name
      (syslog-mode))
    (set-process-filter process 'tail-filter)
    (switch-to-buffer-other-window buffer-name)))


(defun tail-filter (process line)
  "Tail filter called when some output comes."
  (tail-disp-window (process-buffer process) line))


(provide 'tail)

;;; tail.el ends here
