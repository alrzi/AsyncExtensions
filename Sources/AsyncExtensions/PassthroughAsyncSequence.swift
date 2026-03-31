//
//  PassthroughAsyncSequence.swift
//  AsyncExtensions
//
//  Created by Александр Зиновьев on 3/30/26.
//

import Foundation

public final actor PassthroughAsyncSequence<Value>: AsyncSequence where Value: Sendable {
    public typealias Element = Value

    private var continuations = [UUID: AsyncStream<Element>.Continuation]()

    public init() {}

    deinit {
        continuations.values.forEach { $0.finish() }
    }

    public nonisolated func makeAsyncIterator() -> AsyncStream<Value>.Iterator {
        let id = UUID()
        return AsyncStream<Value> { continuation in
            Task { await self.add(id, continuation) }
            continuation.onTermination = { _ in
                Task { await self.remove(id) }
            }
        }.makeAsyncIterator()
    }

    public func send(_ value: Value) {
        continuations.values.forEach { $0.yield(value) }
    }

    private func add(_ id: UUID, _ continuation: AsyncStream<Element>.Continuation) {
        continuations[id] = continuation
    }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }

    public func finish() {
        continuations.values.forEach { $0.finish() }
        continuations.removeAll()
    }
}

public struct PassthroughAsyncSequenceReadOnly<Value>: AsyncSequence where Value: Sendable {
    private let source: PassthroughAsyncSequence<Value>

    init(_ source: PassthroughAsyncSequence<Value>) {
        self.source = source
    }

    public func makeAsyncIterator() -> AsyncStream<Value>.Iterator {
        source.makeAsyncIterator()
    }
}

extension PassthroughAsyncSequence {
    public nonisolated func readOnly() -> PassthroughAsyncSequenceReadOnly<Value> {
        PassthroughAsyncSequenceReadOnly(self)
    }
}
