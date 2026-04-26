(ns my.sample
  (:require [clojure.string :as str]
            [clojure.set :as set]))

(defn greet
  "Greet someone by name."
  [name]
  (println "Hello," name))

(defn process
  [coll]
  (let [doubled (map (fn [x]
                       (* x 2))
                     coll)
        total (reduce + 0
                      doubled)]
    (println "Result:"
             total)))

(def data
  {:name "foo"
   :values [1 2 3
            4 5 6]
   :nested {:a 1
            :b 2}})

(defn weird
  []
  ; bracket in comment: (
  (let [s "string with ( inside"
        c \(]
    c))
