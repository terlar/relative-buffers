;;; relative-buffers.el --- Emacs buffers naming convention

;; Copyright (C) 2014 by Malyshev Artem

;; Author: Malyshev Artem <proofit404@gmail.com>
;; URL: https://github.com/proofit404/relative-buffers
;; Version: 0.0.1
;; Package-Requires: ((cl-lib "0.5") (dash "2.6.0") (s "1.9.0") (f "0.16.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a tiny package that will rename your buffers according to project
;; structure.  For python buffers that will be whole module name.  For temporary
;; files and directories that will be relative path from project root.

;;; Usage:

;; Drop following line into your .emacs file:
;;
;;   (global-relative-buffers-mode)

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 's)
(require 'f)

(defvar relative-buffers-project-markers '(".git" ".hg")
  "List of files marked it directory as project root.")

;;;###autoload
(define-minor-mode relative-buffers-mode
  "Name your buffer relatively to project.
This mode support a lot of naming conventions.
Python buffer named as a module relative to package.
Project file and directories named relative to project root directory."
  :lighter ""
  (when relative-buffers-mode
    (let ((newname (relative-buffers-name)))
      (and newname (rename-buffer newname)))))

;;;###autoload
(define-globalized-minor-mode global-relative-buffers-mode
  relative-buffers-mode
  relative-buffers-mode)

(defun relative-buffers-name ()
  "Give current buffer a relative name."
  (cl-case major-mode
    (python-mode (relative-buffers-python-package))
    (dired-mode (relative-buffers-directory))
    (otherwise (relative-buffers-file-name))))

(defun relative-buffers-python-package ()
  "Python module relative to package."
  (when (file-exists-p "__init__.py")
    (let (name-space-list)
      (when (not (string= "__init__.py" (file-name-nondirectory (buffer-file-name))))
        (setq name-space-list (list (file-name-sans-extension (buffer-file-name)))))
      (cd (file-name-directory (buffer-file-name)))
      (while (file-exists-p (file-truename "__init__.py"))
        (add-to-list 'name-space-list (directory-file-name default-directory))
        (cd ".."))
      (cd (file-name-directory (buffer-file-name)))
      (mapconcat 'file-name-nondirectory name-space-list "."))))

(defun relative-buffers-directory ()
  "Directory relative to project root."
  (let ((root (relative-buffers-project-root))
        (directory (f-full dired-directory)))
    (when (and root (f-ancestor-of? root directory))
      (s-chop-prefix root directory))))

(defun relative-buffers-file-name ()
  "File name relative to project root."
  (--when-let (relative-buffers-project-root)
    (s-chop-prefix it (buffer-file-name))))

(defun relative-buffers-project-root ()
  "Return project root for different VCS."
  (let* ((markers relative-buffers-project-markers)
         (projects (--map (locate-dominating-file default-directory it) markers))
         (roots (-remove 'null projects))
         (dipper-roots (-sort 'f-descendant-of? roots))
         (root (car dipper-roots)))
    (and root (f-full root))))

(provide 'relative-buffers)

;;; relative-buffers.el ends here
