#include <bits/stdc++.h>
using namespace std;

#define int long long int
#define el "\n"
#define p 1000000007
const int N = (int)2e5 + 10;

class MyComp {
public:
    bool operator()(int a, int b) {
        return 2 * a < 3 * b;
    }
};

int solve(istream &in, ostream &out) {
    int n;
    in >> n; // Read an integer from the input stream

    priority_queue<int, vector<int>, MyComp> pq;

    // Operations on the priority queue
    for (int i = 1; i <= n; ++i) {
        pq.push(i);
    }

    while (!pq.empty()) {
        out << pq.top() << " ";
        pq.pop();
    }

    return 0;
}

int32_t main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    solve(cin, cout);

    return 0;
}
