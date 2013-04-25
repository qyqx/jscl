;;; ecmalisp.lisp ---

;; Copyright (C) 2012, 2013 David Vazquez
;; Copyright (C) 2012 Raimon Grau

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(eval-when (:load-toplevel :compile-toplevel :execute)
  (load "compat")
  (load "utils")
  (load "print")
  (load "read")
  (load "compiler"))

(defun read-whole-file (filename)
  (with-open-file (in filename)
    (let ((seq (make-array (file-length in) :element-type 'character)))
      (read-sequence seq in)
      seq)))

(defun ls-compile-file (filename out &key print)
  (let ((*compiling-file* t)
        (*compile-print-toplevels* print))
    (let* ((source (read-whole-file filename))
           (in (make-string-stream source)))
      (format t "Compiling ~a...~%" filename)
      (loop
         for x = (ls-read in)
         until (eq x *eof*)
         for compilation = (ls-compile-toplevel x)
         when (plusp (length compilation))
         do (write-string compilation out)))))

(defun bootstrap ()
  (setq *environment* (make-lexenv))
  (setq *literal-symbols* nil)
  (setq *variable-counter* 0
        *gensym-counter* 0
        *literal-counter* 0
        *block-counter* 0)
  (with-open-file (out "ecmalisp.js" :direction :output :if-exists :supersede)
    (write-string (read-whole-file "prelude.js") out)
    (dolist (file '("boot.lisp"
                    "utils.lisp"
                    "print.lisp"
                    "read.lisp"
                    "compiler.lisp"
                    "toplevel.lisp"))
      (ls-compile-file file out))))
