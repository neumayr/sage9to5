//
//  sage9to5Spec.swift
//  sage9to5Tests
//
//  Created by Matthias Neumayr on 19.04.19.
//  Copyright © 2019 Matthias Neumayr. All rights reserved.
//

import Quick
import Nimble

class TableOfContentsSpec: QuickSpec {
  override func spec() {
    describe("dummy bdd test") {
      it("is everything equal") {
        expect(1 + 1).to(equal(2))
      }

      context("dummy contains") {
        it("needs to contain foobar") {
          expect("foobar").to(contain("bar"))
        }
      }
    }
  }
}
