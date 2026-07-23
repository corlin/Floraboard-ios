//
//  OrderViewModel.swift
//  Floreboard
//
//  ViewModel managing order filter tabs and searching.
//

import Combine
import Foundation

@MainActor
class OrderViewModel: ObservableObject {
  @Published var selectedFilter: OrderStatus? = nil
  @Published var searchText: String = ""

  func filteredOrders(from orders: [OrderRecord]) -> [OrderRecord] {
    orders.filter { order in
      let matchesFilter = selectedFilter == nil || order.status == selectedFilter
      let matchesSearch = searchText.isEmpty
        || order.customerName.localizedCaseInsensitiveContains(searchText)
        || order.customerPhone.contains(searchText)
      return matchesFilter && matchesSearch
    }
  }
}
