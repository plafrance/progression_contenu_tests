;; publish.el --- Publish org-mode project on Gitlab Pages
;; Author: Rasmus

;;; Commentary:
;; This script will convert the org-mode files in this directory into
;; html.

;;; Code:

(setq org-publish-project-alist
      (list
	   (list "doc"
             :base-directory "/tmp/public"
             :base-extension "org"
             :recursive t
             :publishing-function '(org-html-publish-to-html)
             :publishing-directory "/tmp/public"
             :exclude (regexp-opt '("README" "draft" "démo" "thème"))
             :auto-sitemap t
             :sitemap-filename "/tmp/public/index.org"
             :sitemap-file-entry-format "%d *%t*"
             :html-head-extra "<link rel=\"icon\" type=\"image/x-icon\" href=\"/favicon.ico\"/>"
             :sitemap-style 'list
			 )
 ))

(provide 'publish)
;;; publish.el ends here
