//
//  AnyAsyncSequence.swift
//  AsyncExtensions
//
//  Created by Александр Зиновьев on 3/30/26.
//

import Foundation

extension AsyncSequence where Element: Sendable {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
}

public struct AnyAsyncSequence<Element: Sendable>: AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private let _next: () async throws -> Element?

        init<I: AsyncIteratorProtocol>(_ iterator: I) where I.Element == Element {
            var iterator = iterator
            self._next = { try await iterator.next() }
        }

        public mutating func next() async throws -> Element? {
            try await _next()
        }
    }

    private let _makeIterator: () -> Iterator

    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        self._makeIterator = {
            Iterator(sequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> Iterator {
        _makeIterator()
    }
}
