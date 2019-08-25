;;; file-ring.el --- Quickly switch between related files

;; Copyright 2019 Adam Niederer

;; Author: Adam Niederer <adam.niederer@gmail.com>
;; URL: http://github.com/AdamNiederer/file-ring
;; Version: 0.1.0
;; Keywords: files
;; Package-Requires: ((dash "2.16.0") (s "1.12.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Exported names start with "file-ring-"; private names start with
;; "file-ring--".

;;; Code:

(require 'dash)
(require 's)

(defgroup file-ring nil
  "Switch between related files quickly."
  :prefix "file-ring-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/AdamNiederer/file-ring")
  :link '(emacs-commentary-link :tag "Commentary" "file-ring"))

(defcustom file-ring--rings
  '(((:ext ".component.ts" :key "C-t")
     (:ext ".component.scss" :key "C-s")
     (:ext ".component.sass" :key "C-s")
     (:ext ".component.html" :key "C-h")
     (:ext ".component.spec.ts" :key "C-j"))
    ((:ext ".cpp" :key "C-c")
     (:ext ".cc" :key "C-c")
     (:ext ".hpp" :key "C-h")
     (:ext ".hh" :key "C-h")))
  "A list of groups of file exts for quick switching."
  :type '(repeat (repeat (list (const :format "" :ext)
                               (string :format "File Extension: %v")
                               (const :format "" :key)
                               (choice (const :tag "No Quick-Switch Key" :format "No Quick-Switch Key\n" nil)
                                       (string :tag "Quick-Switch Key" :format "Quick-Switch Key: %v")))))
  :group 'file-ring)

(defun file-ring--ring-for (rings name)
  "Find the ring for the file with name NAME in RINGS."
  (declare (pure t) (side-effect-free t))
  (--find (--some (s-ends-with? it name) (--map (plist-get it :ext) it)) rings))

(defun file-ring--base-for (rings name)
  "Find the basename for the file with name NAME in RINGS."
  (declare (pure t) (side-effect-free t))
  (let ((base (file-name-nondirectory name))
        (ext (file-ring--ext-for rings name)))
    (if (and ext (s-ends-with? ext base))
        (substring base 0 (- (length base) (length ext)))
      base)))

(defun file-ring--ext-for (rings name)
  "Find the extension for the file with name NAME in RINGS."
  (declare (pure t) (side-effect-free t))
  (->> (-flatten-n 1 rings)
       (--map (plist-get it :ext))
       (--find (s-ends-with? it name))))

(defun file-ring--rotate-around (el list)
  "Rotate LIST such that EL is at the beginning."
  (declare (pure t) (side-effect-free t))
  (append (--drop-while (not (equal it el)) list)
          (--take-while (not (equal it el)) list)))

(defun file-ring--list (rings buffer-name)
  "List the names of files in BUFFER-NAME's ring in RINGS."
  (declare (pure t) (side-effect-free t))
  (let ((name (file-name-nondirectory buffer-name))
        (base (file-ring--base-for rings buffer-name)))
    (->> (file-ring--ring-for rings name)
         (--map (plist-get it :ext))
         (--map (s-concat base it)))))

(defun file-ring--select (buffer-name names selector)
  "Find the name of the a file in NAMES, according to BUFFER-NAME and SELECTOR."
  (declare (pure t) (side-effect-free t))
  (let ((name (file-name-nondirectory buffer-name)))
    (->> names
         (file-ring--rotate-around name)
         (funcall selector))))

(defun file-ring--filter (create)
  "Return a predicate suitable for filtering file names.

If CREATE is set, allow nonexisting files to pass the predicate."
  (declare (pure t) (side-effect-free t))
  (if create #'identity #'file-exists-p))

(defun file-ring-select (selector create)
  "Open the next file in the current buffer's file ring using SELECTOR.

If CREATE is set, create files which do not exist, instead of skipping them."
  (let ((next (--> (file-ring--list file-ring--rings (buffer-file-name))
                   (-filter (file-ring--filter create) it)
                   (file-ring--select (buffer-file-name) it selector))))
    (when (not next)
      (user-error "No other files found"))
    (find-file next)))

(defun file-ring-next (create)
  "Open the next file in the current buffer's file ring.

If CREATE is set, or a prefix argument is provided when called interactively,
create files which do not exist, instead of skipping them."
  (interactive "P")
  (file-ring-select #'cadr create))

(defun file-ring-prev (create)
  "Open the previous file in the current buffer's file ring.

If CREATE is set, or a prefix argument is provided when called interactively,
create files which do not exist, instead of skipping them."
  (interactive "P")
  (file-ring-select (-compose #'car #'reverse) create))

(defun file-ring--goto-key-prompt (ring)
  "Return a friendly key prompt containing all possible key choices for RING."
  (declare (pure t) (side-effect-free t))
  (--> ring
       (--filter (plist-get it :key) it)
       (--map (plist-get it :key) it)
       (-uniq it)
       (s-join ", " it)
       (s-concat "Go to buffer (" it "):")))

(defun file-ring--goto (ring name key)
  "Find the filenames in RING with basenane NAME corresponding to KEY."
  (declare (pure t) (side-effect-free t))
  (let ((base (file-ring--base-for (list ring) name)))
    (--> ring
         (--filter (equal (plist-get it :key) key) it)
         (--map (s-concat base (plist-get it :ext)) it))))

(defun file-ring--goto-pick (names existing)
  "Select a file name to open in NAMES, given a subset of names in EXISTING."
  (declare (pure t) (side-effect-free t))
  (if existing (first existing) (first names)))

(defun file-ring-goto ()
  "Open a specific file in the current buffer's file ring, if such a ring exists."
  (interactive)
  (let* ((ring (file-ring--ring-for file-ring--rings (buffer-file-name)))
         (key (key-description (list (read-key (file-ring--goto-key-prompt ring)))))
         (nexts (file-ring--goto ring (buffer-file-name) key)))
    (when (not ring)
      (user-error "This buffer doesn't have a ring"))
    (when (not nexts)
      (user-error "No such file exists"))
    (find-file (file-ring--goto-pick nexts (-filter #'file-exists-p nexts)))))

;;;###autoload
(define-minor-mode file-ring-mode
  "Switch between related files quickly."
  nil " ᶂ"
  (list
   (cons (kbd "C-c C-p") #'file-ring-prev)
   (cons (kbd "C-c C-o") #'file-ring-next)
   (cons (kbd "C-c C-i") #'file-ring-goto))
  :group 'file-ring)

(provide 'file-ring)
;;; file-ring.el ends here
